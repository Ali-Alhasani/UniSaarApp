import json
from source.models.MensaModel import Location, Notice, ServingDay, Counter, Component, RGB, Meal, PriceTier, \
    LocationInfo, MensaModel
from dateutil import parser as dateParser


class MensaParser:

    def __init__(self, mensaModel: MensaModel):
        """
        Create a new MensaParser. MensaParser has fields _noticeDict and _priceTierDict that get set during
        parseBaseData. The field _currentID is used to assign IDs to meals.
        """
        self._noticeDict = {}
        self._priceTierDict = {}
        self._mensaModel = mensaModel
        self._currentID = 0

    def dictDataToList(self, dictData: dict, idName: str) -> list:
        """
        Converts a dictionary of some data to a list. The following forms are assumed:
        Input dictionary:
            { "dataID1" : {dataInfo1}, "dataID2" : {dataInfo2}, ... }
            where {dataInfo1} is a dictionary with key-value-pairs dataInfo1
        Output list:
            [ { "idName" : "dataID1", dataInfo1 }, { "idName" : "dataID2", dataInfo2 } ]
        Hence, the dictionary {dataInfo1} gets extended by the key-value pair ("idName": "dataID1")
        @param dictData: a dictionary with dataIDs as keys and data info values
        @param idName: a string which will be used as the key for the dataIDs
        @return a list of dictionaries, where each entry is a dictionary as described above
        """

        dataList = []

        for id, info in dictData.items():
            info[idName] = id
            dataList.append(info)

        return dataList

    def dictToLocation(self, locationDict: dict) -> Location:
        """
        Converts a dictionary of location data to an object of type Location
        @param locationDict: dictionary of the form { "locationID" : id, "displayName" : name, "description" : desc }
        @return Location object
        """

        # should key-value-pairs in the dictionary not be present, set the value to None
        id = locationDict["locationID"] if "locationID" in locationDict.keys() else None
        displayName = locationDict["displayName"] if "displayName" in locationDict.keys() else None
        description = locationDict["description"] if "description" in locationDict.keys() else None

        return Location(id, displayName, description)

    def dictToNotice(self, noticeDict: dict) -> Notice:
        """
        Converts a dictionary of notice data to an object of type Notice
        @param noticeDict: dictionary of the form { "noticeID" : id, "displayName" : name, "isAllergen" : allergen,
                                "isNegated" : negated }
        @return: Notice object
        """

        # should key-value-pairs in the dictionary not be present, set the value to None
        id = noticeDict["noticeID"] if "noticeID" in noticeDict.keys() else None
        displayName = noticeDict["displayName"] if "displayName" in noticeDict.keys() else None
        isAllergen = noticeDict["isAllergen"] if "isAllergen" in noticeDict.keys() else None
        isNegated = noticeDict["isNegated"] if "isNegated" in noticeDict.keys() else None

        return Notice(id, displayName, isAllergen, isNegated)

    def dictToPriceTier(self, priceTierDict: dict) -> PriceTier:
        """
        Converts a dictionary of price tier data to an object of type PriceTier
        @param priceTierDict: dictionary of the form { "priceTierID" : priceTier1_id, "displayName" : priceTier1_name }
        @return: PriceTier object
        """

        # should key-value-pairs in the dictionary not be present, set the value to None
        id = priceTierDict["priceTierID"] if "priceTierID" in priceTierDict.keys() else None
        displayName = priceTierDict["displayName"] if "displayName" in priceTierDict.keys() else None

        return PriceTier(id, displayName)

    def asBaseData(self, dictionary) -> list:
        """
        JSON decoder object hook for mensa baseData JSON.
        Takes a dictionary provided by the decoding of a JSON object and acts on it.
        Current actions are:
        - convert location dictionaries to location lists
        - convert notice dictionaries to notice lists
        - convert known meal dictionaries to known meal lists
        - convert price tier dictionaries to price tier lists
        - find date string belonging to key "lastOffered" in section knownMeals and convert it to datetime object
        @param dictionary: dictionary returned by json.loads of a JSON object
        @return the dictionary with value date-string converted to datetime object
        """
        for key in dictionary.keys():
            if key == "notices":
                dictionary[key] = self.dictDataToList(dictionary[key], "noticeID")
                dictionary[key] = list(map(self.dictToNotice, dictionary[key]))
            if key == "locations":
                dictionary[key] = self.dictDataToList(dictionary[key], "locationID")
                dictionary[key] = list(map(self.dictToLocation, dictionary[key]))
            if key == "knownMeals":
                dictionary[key] = self.dictDataToList(dictionary[key], "knownMealID")
                for lastKnownMeal in dictionary[key]:
                    if "lastOffered" in lastKnownMeal:
                        lastKnownMeal["lastOffered"] = dateParser.parse(lastKnownMeal["lastOffered"])
            if key == "priceTiers":
                dictionary[key] = self.dictDataToList(dictionary[key], "priceTierID")
                dictionary[key] = list(map(self.dictToPriceTier, dictionary[key]))

        return dictionary

    def parseBaseData(self, dataJSON: str) -> dict:
        """
        Parses a JSON returned by the mensa API with the query for baseData.
        Compare with mensa_API_doc.html section getBaseData
        @param dataJSON: a JSON string containing baseData returned by the mensaAPI
        @return nested python dictionary of the form:

            { "notices" : [ Notice1, Notice2, ... ],
            "locations" : [ Location1, Location2, ... ],
            "knownMeals" : [ { "knownMealID" : knMeal1_id, "displayName" : knMeal1_name, "lastOffered" : knMeal1_lastOffered },
                             { "knownMealID" : knMeal2_id, ...}, ... ],
            "priceTiers" : [ PriceTier1, PriceTier2, ... ],
            "globalMessage" : { "title" : message_title, "text" : message_body }
            }

            All keys (i.e. strings in "") will always be provided even if the JSON does not specify them. In this case
            the corresponding value will be None (for missing items on the lowest level, e.g. "displayName" : None)
            or an empty list/dictionary (for missing entries on the highest level, e.g. "globalMessage" : {}).
            All values other than  knMeal_lastOffered will be strings. knMeal_lastOffered will be datetime.datetime
            Should any objects get their own classes/structs, the entries of the corresponding list should be objects
            of that class/struct rather than a dictionary of the form { field_name : field_value, ... }
        """

        rawData = json.loads(dataJSON, object_hook=self.asBaseData)

        # add all missing entries to the dictionary
        # missing entries will be an empty list/dictionary to allow iteration over them
        # tests for existence should hence be via rawData[key].length == 0 rather than via inclusion or tests for None

        if "notices" not in rawData:
            rawData["notices"] = []

        if "locations" not in rawData:
            rawData["locations"] = []

        if "knownMeals" not in rawData:
            rawData["knownMeals"] = []

        if "priceTiers" not in rawData:
            rawData["priceTiers"] = []

        if "globalMessage" not in rawData:
            rawData["globalMessage"] = {}

        # add all missing fields to the entries of rawData[key], that have not already been handled by the JSON_hook
        # the ones handled already are: location, notice and priceTier

        for knownMealItem in rawData["knownMeals"]:
            if "knownMealID" not in knownMealItem:
                knownMealItem["knownMealID"] = None

            if "displayName" not in knownMealItem:
                knownMealItem["displayName"] = None

            if "lastOffered" not in knownMealItem:
                knownMealItem["lastOffered"] = None

        # set fields to be used while parsing menu data
        self._priceTierDict = {priceTier.getId(): priceTier for priceTier in rawData["priceTiers"]}
        self._noticeDict = {notice.getID(): notice for notice in rawData["notices"]}

        return rawData

    def timeIntervalParser(self, timeDict: dict) -> tuple:
        """
        Converts a dictionary of the form { "start": start, "end": end } to a tuple (starttime, endtime)
        where starttime and endtime are datetime objects
        @param timeDict: dictionary as described
        @return: tuple of datetime
        """
        return dateParser.parse(timeDict["start"]), dateParser.parse(timeDict["end"])

    def colorParser(self, rgbDict: dict) -> RGB:
        """
        Converts a dictionary of the form { "r": red, "g": green, "b": blue } to a RGB object
        @param rgbDict: dictionary as described
        @return: RGB object
        """
        return RGB(rgbDict["r"], rgbDict["g"], rgbDict["b"])

    def idToNotice(self, noticeId: str) -> Notice:
        """
        Map a noticeId to the Notice object associated with the id. This method accesses self._noticeDict, which is
        only available after having called parseBaseDate.
        @param noticeId: string
        @return: Notice object
        """
        return self._noticeDict[noticeId]

    def dictToComponent(self, componentDictionary: dict) -> Component:
        """
        Convert a dictionary of component data to object of type Component
        @param componentDictionary: dictionary of the form { "name": compName1, "notices" [ notice1, notice2, ... ] }
        @return: Components object
        """
        name = componentDictionary["name"]
        notices = list(map(self.idToNotice, componentDictionary["notices"]))

        return Component(name, notices)

    def mapPriceTierIdToPrice(self, prices: dict) -> dict:
        """
        Convert a dictionary of priceTierIds and prices to a dictionary of PriceTier and prices.
        In order to do this, the method accesses self._priceTierDict. This is only available after having called
        parseBaseData.
        @param prices: dictionary of the form { priceTierId1: price1, priceTierId2: price2, ... } (string, string)
        @return: dictionary of the form { PriceTier1: price1, PriceTier2: price2, ... } (PriceTier, float)
        """
        return {self._priceTierDict[tierID]: float(price.replace(',', '.')) for tierID, price in prices.items()}

    def dictToMeal(self, mealDictionary: dict) -> Meal:
        """
        Convert dictionary of meal data to object of type Meal
        @param mealDictionary: dictionary of the form
            { "knownMealId": knMealID1, "name": mealName1, "notices": [ notice1, notice2, ... ],
                    "components": [ { "name": compName1, "notices" [ notice3, notice4, ... ] }, { ... }, ... ]
                    "prices": { priceTierId1: price1, priceTierId2: price2, ... },
                    "pricingNotice": pricingNotice, "category": mealCategory }
        The keys "knownMealId", "prices, "pricingNotice" and "category" are optional.
        Since notice1 is just a string of a notice id, noticeList is used to map these ids to Notice objects
        @return: Meal object
        """
        name = mealDictionary["name"]
        notices = list(map(self.idToNotice, mealDictionary["notices"]))
        components = list(map(self.dictToComponent, mealDictionary["components"]))

        knownMealId = mealDictionary["knownMealId"] if "knownMealId" in mealDictionary else None
        prices = self.mapPriceTierIdToPrice(mealDictionary["prices"]) if "prices" in mealDictionary else None
        pricingNotice = mealDictionary["pricingNotice"] if "pricingNotice" in mealDictionary else None
        category = mealDictionary["category"] if "category" in mealDictionary else None

        # temporarily assign ID 0
        meal = Meal(0, name, notices, components, prices, knownMealId, pricingNotice, category)
        mealID = None

        # check the meals currently in the model to see if the same meal exists already. If so, retain the id.
        for lang in ['de', 'en', 'fr']:
            if lang not in self._mensaModel.mealDictionary.keys():
                continue
            for id, mealAndCounter in self._mensaModel.mealDictionary[lang].items():
                if mealAndCounter[0] == meal:
                    mealID = id
                    break
            if mealID is not None:
                break

        if mealID is None:
            mealID = self._currentID
            self._currentID = self._currentID + 1

        meal.setID(mealID)

        return meal

    def dictToCounter(self, counterDictionary: dict) -> Counter:
        """
        Convert dictionary of counter data to object of type Counter
        @param counterDictionary: dictionary of the form
            { "id": id1, "displayName": dName1, "description": desc1,
                    "openingHours": { "start": startOpeningHour1, "end": endOpeningHour1 },
                    "color": { "r": red1, "g": green1, "b": blue1 },
                    "feedback": { "start": startFeedback1, "end": endFeedback1 },
                    "meals":
                        [ { "knownMealId": knMealID1, "name": mealName1, "notices": [ notice1, notice2, ... ],
                            "components": [ { "name": compName1, "notices" [ notice3, notice4, ... ] }, { ... }, ... ]
                            "prices": { priceTier1: price1, priceTier2: price2, ... },
                            "pricingNotice": pricingNotice, "category": mealCategory },
                          { ... },
                        ]
            }
        The keys "openingHours", "color" and "feedback" as well as the keys of a meal "knownMealId", "prices",
        "pricingNotice" and "category" are optional.
        @return Counter object
        """
        id = counterDictionary["id"]
        displayName = counterDictionary["displayName"]
        description = counterDictionary["description"]
        openingHours = self.timeIntervalParser(counterDictionary["openingHours"]) \
            if "openingHours" in counterDictionary else None
        color = self.colorParser(counterDictionary["color"]) if "color" in counterDictionary else None
        feedback = self.timeIntervalParser(counterDictionary["feedback"]) if "feedback" in counterDictionary else None
        meals = list(map(self.dictToMeal, counterDictionary["meals"]))

        return Counter(id, displayName, description, meals, openingHours, color, feedback)

    def dictToServingDay(self, dayDictionary: dict) -> ServingDay:
        """
        Convert dictionary of servingDay data to object of type ServingDay
        @param dayDictionary: dictionary of the form
            { "date": date1, "isPast": isPast1, "counters":
                    [ { "id": id1, "displayName": dName1, "description": desc1,
                        "openingHours": { "start": startOpeningHour1, "end": endOpeningHour1 },
                        "color": { "r": red1, "g": green1, "b": blue1 },
                        "feedback": { "start": startFeedback1, "end": endFeedback1 },
                        "meals":
                            [ { "knownMealId": knMealID1, "name": mealName1, "notices": [ notice1, notice2, ... ],
                                "components": [ { "name": compName1, "notices" [ notice3, notice4, ... ] }, { ... }, ... ]
                                "prices": { priceTier1: price1, priceTier2: price2, ... },
                                "pricingNotice": pricingNotice, "category": mealCategory },
                              { ... },
                            ]
                    }, { ... }, ... ]
            }
        The keys "openingHours", "color" and "feedback" as well as the keys of a meal "knownMealId", "prices",
        "pricingNotice" and "category" are optional.
        @return ServingDay object
        """
        date = dateParser.parse(dayDictionary["date"])
        isPast = dayDictionary["isPast"]
        counters = list(map(self.dictToCounter, dayDictionary["counters"]))

        return ServingDay(date, isPast, counters)

    def asMenuData(self, dictionary: dict) -> list:
        """
        JSON decoder object hook for mensa menuData JSON.
        Takes a dictionary provided by the decoding of a JSON object and acts on it by converting elements of the form
            { "days":
                [ { "date": date1, "isPast": isPast1, "counters":
                    [ { "id": id1, "displayName": dName1, "description": desc1,
                        "openingHours": { "start": startOpeningHour1, "end": endOpeningHour1 },
                        "color": { "r": red1, "g": green1, "b": blue1 },
                        "feedback": { "start": startFeedback1, "end": endFeedback1 },
                        "meals":
                            [ { "knownMealId": knMealID1, "name": mealName1, "notices": [ notice1, notice2, ... ],
                                "components": [ { "name": compName1, "notices" [ notice3, notice4, ... ] }, { ... }, ... ]
                                "prices": { priceTier1: price1, priceTier2: price2, ... },
                                "pricingNotice": pricingNotice, "category": mealCategory },
                              { ... },
                            ]
                    }, { ... }, ... ]
                }, { ... }, ... ]
            }
        to a list of the form
            [ ServingDay1, ServingDay2, ... ]
        The keys "openingHours", "color" and "feedback" as well as the keys of a meal "knownMealId", "prices",
        "pricingNotice" and "category" are optional.
        @param dictionary: dictionary of the form detailed above
        @return: list of ServingDay
        """
        if "days" in dictionary.keys():
            return list(map(self.dictToServingDay, dictionary["days"]))
        else:
            return dictionary

    def parseMenuData(self, menuJSON: str) -> list:
        """
        Parses a JSON returned by the mensa API with the query for menuData.
        Compare with mensa_API_doc.html section getMenu
        Assumes that parseBaseData has been called before.
        @param menuJSON: a JSON string containing menuData returned by the mensaAPI
        @return: list of the form: [ ServingDay1, ServingDay2, ... ]
        """
        servingDays = json.loads(menuJSON, object_hook=self.asMenuData)

        return servingDays

    def parseLocationInfo(self, locationInfoJSON: str) -> dict:
        """
        Parses a JSON containing information about a location.
        The given fields should be id, name, description and image, i.e.:
             { "id": id (str), "image" imageLink (str),
               "langData": [ { "lang": language (str), "name": name (str), "description": description (str) }, { ... } ]
             }
        @param locationInfoJSON: a JSON string containing locationInfo
        @return: dictionary of language string to LocationInfo object
        """
        locationInfoData = json.loads(locationInfoJSON)
        langDict = {}
        for langData in locationInfoData['langData']:
            language = langData['lang']
            langDict[language] = LocationInfo(locationInfoID=locationInfoData['id'], name=langData['name'],
                                              description=langData['description'], imageLink=locationInfoData['image'])

        return langDict
