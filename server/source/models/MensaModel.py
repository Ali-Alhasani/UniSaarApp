from datetime import datetime
from collections import Counter as CollectionCounter
from source.ReadWriteLock import RWLock
from source.Constants import MENSA_UPDATE_THRESHOLD_WORKING_HOURS

mensaLock = RWLock()


class MensaModel:

    def __init__(self):
        """
        Creates a new mensaModel object. It has dictionaries of language codes to the following data structures:
        empty lists for locations and baseData like notices, price tiers,
        known meals, a dictionary of mealID to (meal, counter), a dictionary of locationID to locationInfo,
        as well as an empty dictionary for global messages.
        These fields should only get filled via the method update.
        Upon creation the date lastUpdated is set to None.
        """
        self.locations = {}
        self.notices = {}
        self.priceTiers = {}
        self.knownMeals = {}
        self.globalMessage = {}
        self.mealDictionary = {}
        self.locationInfoDictionary = {}
        self.lastUpdated = None
        self.UPDATE_THRESHOLD = MENSA_UPDATE_THRESHOLD_WORKING_HOURS
        self.filtersLastChanged = {}

    def update(self, baseData: dict, menuData: dict, language: str, updateTime: datetime = None):
        """
        Updates the mensa model to include the base data and location data provided.
        Any previous data in the language will be overwritten.
        Once this is written, the lastUpdated field gets set to the current time or, if provided, the updateTime,
        which denotes the time, the data was retrieved
        @param baseData: A dictionary as it gets returned by ..MensaParser.parseBaseData(JSON)
        @param menuData: A dictionary of string to Location,
            key is a locationID, value as it gets returned by ..MensaParser.parseMenuData(JSON) for the corresponding ID
        @param language: string, the language in which the data provided is in
        @param updateTime: optional, datetime object with the timestamp of the retrieved data
        """

        # Before updating the locations and notices (i.e. filter information), check if the locations have changed.
        # If so, update filtersLastChanged. Set the locations and notices again anyway, since we want to have no menus
        # before setting the new ones
        mensaLock.acquire_write()
        try:
            if (language not in self.locations.keys()) or (language not in self.notices.keys()):
                self.filtersLastChanged[language] = datetime.now()
            elif not (CollectionCounter(self.locations[language]) == CollectionCounter(baseData["locations"])
                      or CollectionCounter(self.notices[language]) == CollectionCounter(baseData["notices"])):
                self.filtersLastChanged[language] = datetime.now()
            self.locations[language] = baseData["locations"]
            self.notices[language] = baseData["notices"]
            self.priceTiers[language] = baseData["priceTiers"]
            self.knownMeals[language] = baseData["knownMeals"]
            self.globalMessage[language] = baseData["globalMessage"]
            self.mealDictionary[language] = {}

            # set the menu data in each location
            tempDays = []
            for location in self.locations[language]:
                # TODO this is a hopefully temporary workaround to add the contents of the forum international and the
                # mensagarten to the sb menu
                if location.getID() not in ['sb', 'forum', 'mensagarten']:
                    location.setMenu(menuData[location.getID()])
                elif location.getID() in ['forum', 'mensagarten']:
                    tempDays = tempDays + menuData[location.getID()]
                    location.setMenu([])
            sbMenu = menuData['sb'] + tempDays
            for location in self.locations[language]:
                if location.getID() == 'sb':
                    location.setMenu(sbMenu)

                # gather the meals and counters of each location and add them to mealDictionary
                for servingDay in location.getMenu():
                    for counter in servingDay.getCounters():
                        for meal in counter.getMeals():
                            self.mealDictionary[language][meal.getID()] = (meal, counter)

            if updateTime is None:
                self.lastUpdated = datetime.now()
            else:
                self.lastUpdated = updateTime
        finally:
            mensaLock.release()

    def updateLocationInfo(self, locationInfo: dict):
        """
        @param locationInfo: a dictionary of language to a dictionary of locationID to locationInfo
        """
        mensaLock.acquire_write()
        try:
            self.locationInfoDictionary = locationInfo
        finally:
            mensaLock.release()

    def isUpToDate(self):
        """
        Compares the current time to the lastUpdated. If the difference exceeds a predefined threshold, return False
        @return True, if the lastUpdated time is less than self.UPDATETHRESHOLD away from now
        """
        mensaLock.acquire_read()
        try:
            if self.lastUpdated is None:
                isUpToDate = False
            else:
                isUpToDate = (datetime.now() - self.lastUpdated) < self.UPDATE_THRESHOLD
            return isUpToDate
        finally:
            mensaLock.release()

    def getFiltersLastChanged(self, language) -> datetime:
        """
        Getter for filtersLastChanged
        @param: string, a language code
        @return: datetime
        """
        mensaLock.acquire_read()
        try:
            filtersLastChanged = self.filtersLastChanged[language]
            return filtersLastChanged
        finally:
            mensaLock.release()

    def getLocation(self, locationID: str, language: str):
        """
        Getter for a Location in a language
        @param locationID: string, the location's id
        @param language: string, language code
        """
        mensaLock.acquire_read()
        try:
            targetLocation = None
            if language not in self.locations.keys():
                raise KeyError

            for location in self.locations[language]:
                if location.getID() == locationID:
                    targetLocation = location
                    break
            if targetLocation is None:
                raise ValueError
            return targetLocation
        finally:
            mensaLock.release()

    def getMealAndCounter(self, mealID: int, language: str) -> tuple:
        """
        Getter for the tuple (meal, counter) of a certain mealID in a language.
        @param mealID: int, the meal's id
        @param language: string, language code
        @return: tuple, a pair (Meal, Counter)
        """
        mensaLock.acquire_read()
        try:
            if language not in self.mealDictionary.keys():
                raise KeyError

            if mealID not in self.mealDictionary[language].keys():
                raise KeyError

            meal, counter = self.mealDictionary[language][mealID]
            return meal, counter
        finally:
            mensaLock.release()

    def getLocationInfo(self, locationID: str, language: str):
        """
        Getter for the location info in a language.
        @param locationID: string, the location's id
        @param language: string, language code
        @return: LocationInfo object
        """
        mensaLock.acquire_read()
        try:
            if language not in self.locationInfoDictionary.keys():
                raise KeyError

            if locationID not in self.locationInfoDictionary[language].keys():
                raise KeyError

            locationInfo = self.locationInfoDictionary[language][locationID]
            return locationInfo
        finally:
            mensaLock.release()

    def getLocations(self, language: str):
        """
        Getter for the list of locations in a language
        @param language: str
        @return: list
        """
        if language not in self.locations.keys():
            return self.locations['de']
        else:
            return self.locations[language]

    def getNotices(self, language: str):
        """
        Getter for the list of notices in a language
        @param language: str
        @return: list
        """
        if language not in self.notices.keys():
            return self.notices['de']
        else:
            return self.notices[language]


class LocationInfo:

    def __init__(self, locationInfoID: str, name: str, description: str, imageLink: str = None):
        """
        Creates a location info. This is necessary since the mensa API (for now) doesn't provide all needed information
        in the App. Updates to this should be done by parsing a file located on the Server.
        @param locationInfoID: str
        @param name: str
        @param description: str
        @param imageLink: str
        """
        self._locationInfoLock = RWLock()
        self._locationInfoID = locationInfoID
        self._name = name
        self._description = description
        self._imageLink = imageLink

    def setID(self, locationInfoID: str):
        """
        Setter for the ID
        @param locationInfoID: string
        """
        self._locationInfoLock.acquire_write()
        self._locationInfoID = locationInfoID
        self._locationInfoLock.release()

    def getID(self):
        """
        Getter for the ID
        @return: string
        """
        self._locationInfoLock.acquire_read()
        lid = self._locationInfoID
        self._locationInfoLock.release()
        return lid

    def setName(self, name: str):
        """
        Setter for the name
        @param name: string
        """
        self._locationInfoLock.acquire_write()
        self._name = name
        self._locationInfoLock.release()

    def getName(self):
        """
        Getter for the name
        @return: string
        """
        self._locationInfoLock.acquire_read()
        name = self._name
        self._locationInfoLock.release()
        return name

    def setDescription(self, description: str):
        """
        Setter for the description
        @param description: string
        """
        self._locationInfoLock.acquire_write()
        self._description = description
        self._locationInfoLock.release()

    def getDescription(self):
        """
        Getter for the description
        @return: string
        """
        self._locationInfoLock.acquire_read()
        desc = self._description
        self._locationInfoLock.release()
        return desc

    def setImageLink(self, imageLink: str):
        """
        Setter for the image link
        @param imageLink: string
        """
        self._locationInfoLock.acquire_write()
        self._imageLink = imageLink
        self._locationInfoLock.release()

    def getImageLink(self):
        """
        Getter for the image link
        @return: string
        """
        self._locationInfoLock.acquire_read()
        il = self._imageLink
        self._locationInfoLock.release()
        return il


class Location:

    def __init__(self, id: str, name: str, description: str):
        """
        Creates a food location. Each location has a unique ID by which it will be distinguished, a name that will
        be displayed and a description. The uniqueness is not enforced here but should be in the MensaModel that
        manages all locations. We assume the uniqueness due to the MensaAPI documentation.
        Additionally each location has a list "menu", that is not assigned upon creation.
        Should the mensaAPI eventually provide opening hours, they should also be stored here, rather than in the
        separate MensaInfoModel
        @param id: a string containing the locations id
        @param name: a string containing a human readable name
        @param description: a string containing a description
        """
        self._id = id
        self._name = name
        self._description = description
        self._menu = []
        self._lock = RWLock()

    def __eq__(self, other):
        """
        Equals for locations. A location is the same as another one, iff their ids match
        @param other: object
        @return: bool
        """
        if not isinstance(other, Location):
            return False
        self._lock.acquire_read()
        try:
            return self._id == other.getID()
        finally:
            self._lock.release()

    def __hash__(self):
        """
        Hash for location. Uses the id.
        @return: int
        """
        self._lock.acquire_read()
        try:
            return hash(self._id)
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the location's name
        @param name: string of the name
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def setID(self, id: str):
        """
        Setter for the location's ID
        @param id: string of the ID
        """
        self._lock.acquire_write()
        try:
            self._id = id
        finally:
            self._lock.release()

    def setDescription(self, description: str):
        """
        Setter for the location's description
        @param description: string of the description
        """
        self._lock.acquire_write()
        try:
            self._description = description
        finally:
            self._lock.release()

    def setMenu(self, menu):
        """
        Setter for the location's menu.
        @param menu: list of ServingDay
        """
        self._lock.acquire_write()
        try:
            self._menu = menu
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the location's description
        @return: string of the name
        """
        self._lock.acquire_read()
        try:
            if self._id == 'sb':
                return 'Saarbrücken'
            if self._id == 'hom':
                return 'Homburg'
            else:
                return self._name
        finally:
            self._lock.release()

    def getID(self):
        """
        Getter for the location's ID
        @return: string of the ID
        """
        self._lock.acquire_read()
        try:
            return self._id
        finally:
            self._lock.release()

    def getDescription(self):
        """
        Getter for the location's description
        @return: string of the description
        """
        self._lock.acquire_read()
        try:
            return self._description
        finally:
            self._lock.release()

    def getMenu(self, date: datetime = None):
        """
        Getter for the location's menu. If specified, the only element in the list will be the one with date date. Else,
        all ServingDays will be returned.
        @param date: datetime (optional, default: None), date of the requested menu
        @return: list of ServingDay
        """
        self._lock.acquire_read()
        try:
            if date is None:
                return self._menu
            else:
                for day in self._menu:
                    if (date.day, date.month) == (day.getDate().day, day.getDate().month):
                        return [day]

                return []
        finally:
            self._lock.release()


class ServingDay:

    def __init__(self, date: datetime, isPast: bool, counters: list):
        """
        Creates a ServingDay. Each ServingDay has its actual date, whether it lies in the past and a list of Counters
        @param date: datetime object denoting the date
        @param isPast: boolean, saying whether this day lies in the past
        @param counters: a list of Counters offered at this date
        """
        self._date = date
        self._isPast = isPast
        self._counters = counters
        self._lock = RWLock()

    def setDate(self, date: datetime):
        """
        Setter for the date
        @param date: datetime object
        """
        self._lock.acquire_write()
        try:
            self._date = date
        finally:
            self._lock.release()

    def setIsPast(self, isPast: bool):
        """
        Setter for the isPast field
        @param isPast: bool
        """
        self._lock.acquire_write()
        try:
            self._isPast = isPast
        finally:
            self._lock.release()

    def setCounters(self, counters: list):
        """
        Setter for the counters
        @param counters: list of Counters
        """
        self._lock.acquire_write()
        try:
            self._counters = counters
        finally:
            self._lock.release()

    def getDate(self):
        """
        Getter for the date
        @return: datetime object
        """
        self._lock.acquire_read()
        try:
            return self._date
        finally:
            self._lock.release()

    def getIsPast(self):
        """
        Getter for the isPast field
        @return: bool
        """
        self._lock.acquire_read()
        try:
            return self._isPast
        finally:
            self._lock.release()

    def getCounters(self):
        """
        Getter for the counters
        @return: list of Counters
        """
        self._lock.acquire_read()
        try:
            return self._counters
        finally:
            self._lock.release()


class RGB:

    def __init__(self, r: int, g: int, b: int):
        """
        Creates a RGB object
        @param r: int, red value
        @param g: int, green value
        @param b: int, blue value
        """
        self._r = r
        self._g = g
        self._b = b

    def getDict(self) -> dict:
        """
        Creates a dictionary of the form { "r": r, "g": g, "b": b }
        @return: dict
        """
        return {"r": self._r, "g": self._g, "b": self._b}


class Counter:

    def __init__(self, id: str, name: str, description: str, meals: list, openingHours: tuple = None,
                 color: RGB = None, feedback: tuple = None):
        """
        Creates a counter object with unique (see uniqueness of location) ID, name, description, a list of meals
        offered there, openingHours (optional), color (optional) and feedbackTime (optional)
        @param id: string
        @param name: string
        @param description: string
        @param openingHours: optional, pair of datetime denoting opening and closing hours
        @param color: optional, RGB
        @param feedback: optional, pair of datetime denoting the interval during which feedback can be provided
        @param meals: list of Meal
        """
        self._id = id
        self._name = name
        self._description = description
        self._openingHours = openingHours
        self._color = color
        self._feedback = feedback
        self._meals = meals
        self._lock = RWLock()

    def __eq__(self, other):
        """
        Equality for Counters. Equality holds, iff the ids match
        @param other: object
        @return: bool
        """
        if not isinstance(other, Counter):
            return False

        self._lock.acquire_read()
        try:
            return other.getID() == self._id
        finally:
            self._lock.release()

    def __hash__(self):
        """
        Hash for Counters. Uses the id
        @return: int
        """
        self._lock.acquire_read()
        try:
            return hash(self._id)
        finally:
            self._lock.release()

    def setID(self, id: str):
        """
        Setter for the id
        @param id: string
        """
        self._lock.acquire_write()
        try:
            self._id = id
        finally:
            self._lock.release()

    def getID(self):
        """
        Getter for the id
        @return: string containing id
        """
        self._lock.acquire_read()
        try:
            return self._id
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the name
        @param name: string
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the name
        @return: string containing the name
        """
        self._lock.acquire_read()
        try:
            return self._name
        finally:
            self._lock.release()

    def setDescription(self, description: str):
        """
        Setter for the description
        @param description: string
        """
        self._lock.acquire_write()
        try:
            self._description = description
        finally:
            self._lock.release()

    def getDescription(self):
        """
        Getter for the description
        @return: string containing description
        """
        self._lock.acquire_read()
        try:
            return self._description
        finally:
            self._lock.release()

    def setOpeningHours(self, openingHours: tuple):
        """
        Setter for the opening hours
        @param openingHours: pair of datetime denoting opening and closing hours
        """
        self._lock.acquire_write()
        try:
            self._openingHours = openingHours
        finally:
            self._lock.release()

    def getOpeningHours(self):
        """
        Getter for the opening hours
        @return: pair of datetime denoting opening and closing hours
        """
        self._lock.acquire_read()
        try:
            return self._openingHours
        finally:
            self._lock.release()

    def setColor(self, color: RGB):
        """
        Setter for the color
        @param color: RGB
        """
        self._lock.acquire_write()
        try:
            self._color = color
        finally:
            self._lock.release()

    def getColor(self):
        """
        Getter for the color
        @return: RGB
        """
        self._lock.acquire_read()
        try:
            return self._color
        finally:
            self._lock.release()

    def setFeedback(self, feedback: tuple):
        """
        Setter for the feedback time
        @param feedback: pair of datetime denoting the interval during which feedback can be provided
        """
        self._lock.acquire_write()
        try:
            self._feedback = feedback
        finally:
            self._lock.release()

    def getFeedback(self):
        """
        Getter for the feedback time
        @return: pair of datetime denoting the interval during which feedback can be provided
        """
        self._lock.acquire_read()
        try:
            return self._feedback
        finally:
            self._lock.release()

    def setMeals(self, meals: list):
        """
        Setter for the meals
        @param meals: list of Meal
        """
        self._lock.acquire_write()
        try:
            self._meals = meals
        finally:
            self._lock.release()

    def getMeals(self):
        """
        Getter for the meals
        @return: list of Meal
        """
        self._lock.acquire_read()
        try:
            return self._meals
        finally:
            self._lock.release()


class Meal:

    def __init__(self, mealID: int, name: str, notices: list, components: list, prices: dict = None, knownMealID: str = None,
                 pricingNotice: str = None, category: str = None):
        """
        Creates a new meal. Each Meal has a name, a list of notices and a list components its made up of, a dictionary
        of prices assigning prices to priceTiers and optionally a knownMealID, a pricingNotice to be displayed instead
        of the prices and a category.
        @param mealID: id
        @param name: string
        @param notices: list of Notices
        @param components: list of Components
        @param prices: optional, dictionary of PriceTier and float
        @param knownMealID: optional, a (unique) string
        @param pricingNotice: optional, string
        @param category: optional, string
        """
        self._mealID = mealID
        self._name = name
        self._notices = notices
        self._components = components
        self._prices = prices
        self._knownMealID = knownMealID
        self._pricingNotice = pricingNotice
        self._category = category
        self._lock = RWLock()

    def __eq__(self, other):
        """
        Equality for Meal. Equality holds iff the the name, notices, components, prices, knownMealID, pricingNotice and
        category are equal.
        @param other: object
        @return: bool
        """
        if not isinstance(other, Meal):
            return False
        self._lock.acquire_read()
        try:
            nameEq = self._name == other.getName()
            noticeEq = CollectionCounter(self._notices) == CollectionCounter(other.getNotices())
            componentEq = CollectionCounter(self._components) == CollectionCounter(other.getComponents())
            if self._prices is not None:
                if other.getPrices() is not None:
                    priceEq = CollectionCounter(self._prices.items()) == CollectionCounter(other.getPrices().items())
                else:
                    return False
            else:
                if other.getPrices() is not None:
                    return False
                else:
                    priceEq = True
            knownMealEq = self._knownMealID == other.getKnownMealID()
            pricingNoticeEq = self._pricingNotice == other.getPricingNotice()
            categoryEq = self._category == other.getCategory()

            return nameEq and noticeEq and componentEq and priceEq and knownMealEq and pricingNoticeEq and categoryEq
        finally:
            self._lock.release()

    def __hash__(self):
        """
        Hash for Meal
        @return: int
        """
        self._lock.acquire_read()
        try:
            nameHash = hash(self._name)
            noticeHash = sum([hash(notice) for notice in self._notices])
            componentHash = sum([hash(component) for component in self._components])
            if self._prices is None:
                priceHash = hash(self._prices)
            else:
                priceHash = sum([hash(pricePoint) for pricePoint in self._prices.items()])
            knownMealHash = hash(self._knownMealID)
            pricingNoticeHash = hash(self._pricingNotice)
            categoryHash = hash(self._category)

            return nameHash + noticeHash + componentHash + priceHash + knownMealHash + pricingNoticeHash + categoryHash
        finally:
            self._lock.release()

    def setID(self, mealID: int):
        """
        Setter for the id
        @param mealID: int
        """
        self._lock.acquire_write()
        try:
            self._mealID = mealID
        finally:
            self._lock.release()

    def getID(self):
        """
        Getter for the id
        @return: int
        """
        self._lock.acquire_read()
        try:
            return self._mealID
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the name
        @param name: string
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the name
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._name
        finally:
            self._lock.release()

    def setNotices(self, notices: list):
        """
        Setter for the notices
        @param notices: list of Notices
        """
        self._lock.acquire_write()
        try:
            self._notices = notices
        finally:
            self._lock.release()

    def getNotices(self):
        """
        Getter for the notices
        @return: list of Notices
        """
        self._lock.acquire_read()
        try:
            return self._notices
        finally:
            self._lock.release()

    def setComponents(self, components: list):
        """
        Setter for the components
        @param components: list of Components
        """
        self._lock.acquire_write()
        try:
            self._components = components
        finally:
            self._lock.release()

    def getComponents(self):
        """
        Getter for the components
        @return: list of Components
        """
        self._lock.acquire_read()
        try:
            return self._components
        finally:
            self._lock.release()

    def setPrices(self, prices: dict):
        """
        Setter for the prices
        @param prices: dict of string to float
        """
        self._lock.acquire_write()
        try:
            self._prices = prices
        finally:
            self._lock.release()

    def getPrices(self):
        """
        Getter for the prices
        @return: dict of string to float
        """
        self._lock.acquire_read()
        try:
            return self._prices
        finally:
            self._lock.release()

    def setKnownMealID(self, knownMealID: str):
        """
        Setter for the known meal id
        @param knownMealID: string
        """
        self._lock.acquire_write()
        try:
            self._knownMealID = knownMealID
        finally:
            self._lock.release()

    def getKnownMealID(self):
        """
        Getter for the known meal id
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._knownMealID
        finally:
            self._lock.release()

    def setPricingNotice(self, pricingNotice: str):
        """
        Setter for the pricing notice
        @param pricingNotice: string
        """
        self._lock.acquire_write()
        try:
            self._pricingNotice = pricingNotice
        finally:
            self._lock.release()

    def getPricingNotice(self):
        """
        Getter for the pricing notice
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._pricingNotice
        finally:
            self._lock.release()

    def setCategory(self, category: str):
        """
        Setter for the category
        @param category: string
        """
        self._lock.acquire_write()
        try:
            self._category = category
        finally:
            self._lock.release()

    def getCategory(self):
        """
        Getter for the category
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._category
        finally:
            self._lock.release()


class Notice:

    def __init__(self, id: str, name: str, isAllergen: bool, isNegated: bool):
        """
        Creates a new notice. Each notice has a unique (see location) id, a readable name and knows whether it
        is an allergen or whether it denotes the absence or existence of itself.
        The name gets put in lowercase with just the first letter capitalized.
        @param id: string
        @param name: string
        @param isAllergen: bool
        @param isNegated: bool, if True the component is not included
        """
        self._id = id
        self._name = name.capitalize() if name is not None else name
        self._isAllergen = isAllergen
        self._isNegated = isNegated
        self._lock = RWLock()

    def __eq__(self, other):
        """
        Equality for notices. A notice is the same as another one, iff the ids match
        @param other: object
        @return: bool
        """
        if not isinstance(other, Notice):
            return False
        self._lock.acquire_read()
        try:
            return self._id == other.getID()
        finally:
            self._lock.release()

    def __hash__(self):
        """
        hash function for notices, should return the same hash for Notices that are __eq__
        :return: the hash value for the Notice object in question
        """
        self._lock.acquire_read()
        try:
            return self._id.__hash__()
        finally:
            self._lock.release()

    def setID(self, id: str):
        """
        Setter for the id
        @param id: string
        """
        self._lock.acquire_write()
        try:
            self._id = id
        finally:
            self._lock.release()

    def getID(self):
        """
        Getter for the id
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._id
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the name
        @param name: string
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the name
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._name
        finally:
            self._lock.release()

    def setIsAllergen(self, isAllergen: bool):
        """
        Setter for isAllergen
        @param isAllergen: bool
        """
        self._lock.acquire_write()
        try:
            self._isAllergen = isAllergen
        finally:
            self._lock.release()

    def getIsAllergen(self):
        """
        Getter for isAllergen
        @return: bool
        """
        self._lock.acquire_read()
        try:
            return self._isAllergen
        finally:
            self._lock.release()

    def setIsNegated(self, isNegated: bool):
        """
        Setter for isNegated
        @param isNegated: bool
        """
        self._lock.acquire_write()
        try:
            self._isNegated = isNegated
        finally:
            self._lock.release()

    def getIsNegated(self):
        """
        Getter for isNegated
        @return: bool
        """
        self._lock.acquire_read()
        try:
            return self._isNegated
        finally:
            self._lock.release()


class Component:

    def __init__(self, name: str, notices: list):
        """
        Creates the component of a meal. Each component has a name and a list of notices concerning itself
        @param name: string
        @param notices: list of Notices
        """
        self._name = name
        self._notices = notices
        self._lock = RWLock()

    def __eq__(self, other):
        """
        Equality for Component holds iff the name and the notices are equal
        @param other: object
        @return: bool
        """
        if not isinstance(other, Component):
            return False
        self._lock.acquire_read()
        try:
            noticeEq = CollectionCounter(self._notices) == CollectionCounter(other.getNotices())

            return self._name == other.getName() and noticeEq
        finally:
            self._lock.release()

    def __hash__(self):
        """
        Hash for Component
        @return: int
        """
        self._lock.acquire_read()
        try:
            noticeHash = sum([hash(notice) for notice in self._notices])
            return hash(self._name) + noticeHash
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the name
        @param name: string
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the name
        @return: string
        """
        self._lock.acquire_read()
        try:
            return self._name
        finally:
            self._lock.release()

    def setNotices(self, notices: list):
        """
        Setter for the notices
        @param notices: list of Notices
        """
        self._lock.acquire_write()
        try:
            self._notices = notices
        finally:
            self._lock.release()

    def getNotices(self):
        """
        Getter for the notices
        @return: list of Notices
        """
        self._lock.acquire_read()
        try:
            return self._notices
        finally:
            self._lock.release()


class PriceTier:

    def __init__(self, tierId: str, name: str):
        """
        Creates a priceTier object. Each priceTier has a (unique) id and a name
        @param tierId: str
        @param name: str
        """
        self._lock = RWLock()
        self._id = tierId
        self._name = name

    def __eq__(self, other):
        """
        Equality for PriceTier holds iff the ids are the same
        @param other: object
        @return: bool
        """
        if not isinstance(other, PriceTier):
            return False
        self._lock.acquire_read()
        try:
            return self._id == other.getId()
        finally:
            self._lock.release()

    def __hash__(self):
        """
        Hash for PriceTier
        @return: int
        """
        self._lock.acquire_read()
        try:
            return hash(self._id)
        finally:
            self._lock.release()

    def setId(self, tierId: str):
        """
        Setter for the id
        @param tierId: str
        """
        self._lock.acquire_write()
        try:
            self._id = tierId
        finally:
            self._lock.release()

    def getId(self):
        """
        Getter for the id
        @return: str
        """
        self._lock.acquire_read()
        try:
            return self._id
        finally:
            self._lock.release()

    def setName(self, name: str):
        """
        Setter for the name
        @param name: str
        """
        self._lock.acquire_write()
        try:
            self._name = name
        finally:
            self._lock.release()

    def getName(self):
        """
        Getter for the name
        @return: str
        """
        self._lock.acquire_read()
        try:
            return self._name
        finally:
            self._lock.release()
