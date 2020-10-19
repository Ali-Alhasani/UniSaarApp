from datetime import datetime, timedelta
from source.ReadWriteLock import RWLock
from collections import Counter as collectionCounter
from source.Constants import DIRECTORY_CACHE_THRESHOLD, DIRECTORY_IMAGE_BASE_LINK

directoryLock = RWLock()


def hasWordBeginningWith(sentence: str, query: str) -> bool:
    """
    Checks if the sentence contains a word beginning with the query.
    By default, words are considered substrings separated by any of the characters in this string: " ,.'-".
    If one of these symbols appears in the query, the sentence is not split by these characters.
    This method should be used to sort the list of GeneralPerson in a SearchItem
    @param sentence: str
    @param query: str
    @return: bool
    """
    words = [sentence]

    # split the sentence into words by each valid separator
    for char in " ,.'-":
        if char not in query:
            newWords = []
            # split each word by the next separator
            for word in words:
                newWords += word.split(char)

            words = newWords  # replace the previous list of words by the new one

    # Check if one of the words begins with the query, ignore casing
    for word in words:
        if word.lower().startswith(query.lower()):
            return True

    return False


def hasPage(page: int, pageSize: int, itemCount: int):
    """
    Checks whether a certain page exists
    @param page:
    @param pageSize:
    @param itemCount:
    @return: bool
    """
    return page*pageSize < itemCount


def createSecretPerson(pid):
    """
    Creates a "secret" person. The pid determines who is returned
    @return: Ali
    """
    if pid == -1:
        return DetailedPerson(firstname='Ali', lastname='Alhasani', academicTitle='The App Guy',
                              gender='männlich', officeHour='', remarks='don\'t push to the master!, '
                                                                        'I\'m having merge conflicts and I hate my life',
                              postalCode='',
                              city='but you can always find me in the nearest bar or night club ;)',
                              street='no roots (XXA)', office='', building='no where.',
                              phone='you can\'t get my number that easily!', mail='I\'m still using MSN',
                              fax='only when my bank account looks like Fax number', webpage='',
                              imageLink=DIRECTORY_IMAGE_BASE_LINK + 'AAlhasani.jpeg', functions=[])
    elif pid == -2:
        return DetailedPerson(firstname='Anthony', lastname='Heggen', academicTitle='Count', gender='männlich',
                              officeHour='Dusk - Dawn', remarks='Blood donations optional, but greatly appreciated',
                              postalCode='', city='Cluj', street='', office='Office Dracula', building='Castle Dracula',
                              phone='Call me for a consultation', mail='',
                              fax='and I\'ll mail you an 18kg crate full of live, loose fruit bats\n I don\'t need fruit bats',
                              webpage='https://www.drk-blutspende.de/', functions=[])
    elif pid == -3:
        return DetailedPerson(firstname='Julien', lastname='Schanz', academicTitle='Smooth Operator', gender='männlich',
                              officeHour='Never', remarks='The birds work for the bourgeoisie', postalCode='0',
                              city='Dunno-Ville', street='Dunno street, 0', office='', building='', phone='',
                              mail='"There can always be things."',
                              fax='', webpage='', functions=[])
    elif pid == -4:
        return DetailedPerson(firstname='Matias', lastname='Klimpel', academicTitle='Appreciator Of Vogon Poetry',
                              gender='männlich', officeHour='31.02.',
                              remarks='We apologize for the inconvenience.',
                              postalCode='', city='of the Universe', street='at the End', office='',
                              building='The Restaurant',
                              phone='42 is not proven to be the answer to everything,', mail='',
                              fax="but rather the answer to the 'Ultimate Question of Life, the Universe and Everything'.",
                              webpage='', imageLink=DIRECTORY_IMAGE_BASE_LINK + 'MKlimpel.jpeg',
                              functions=[])
    elif pid == -5:
        return DetailedPerson(firstname='Serdar', lastname='Durdyyev', academicTitle='', gender='männlich',
                              officeHour='', remarks='The Map Guy', postalCode='', city='', street='', office='',
                              building='', phone='', mail='', fax='', webpage='', functions=[])
    elif pid == -6:
        return DetailedPerson(firstname='Varsha', lastname='Gattu', academicTitle='Ramenator', gender='weiblich',
                              officeHour='is it still a thing?', remarks='Talk to my assistant, whoever that is',
                              postalCode='', city='Never mind', street='Why am I still here?', office='I\'m stuck',
                              building='I\'m getting out of here', phone='', fax='', mail='', webpage='', functions=[])


class SearchItem:

    def __init__(self, query: str):
        """
        Constructor for a search item.
        """
        self._query = query
        self._lastChanged = datetime.now()
        self._searchResults = []
        self._lock = RWLock()

    def update(self, results: list):
        """
        Updates the search item by adding all entries in results, that are not yet in the searchResults.
        @param results: list of GeneralPerson
        """
        self._lock.acquire_write()
        try:
            for r in results:
                if r not in self._searchResults:
                    self._searchResults.append(r)

            self._lastChanged = datetime.now()
        finally:
            self._lock.release()

    def sortResults(self):
        """
        Sorts the results by the following hierarchical rules:
        1) Show people first, whose last name contains a word beginning with the search query
        2) Then show people, whose first name contains a word beginning with the search query
        3) Then show the rest
        Within the categories, use lexicographical order first within the last names and then within the first names
        """
        # Sort is stable, i.e. keeps the order of elements that are compared as equal
        # Hence sort according to the hierarchical rules in reverse order
        self._lock.acquire_write()
        try:
            self._searchResults.sort(key=lambda gp: gp.getFirstname())  # sort by first names
            self._searchResults.sort(key=lambda gp: gp.getLastname())  # sort by last names
            self._searchResults.sort(key=lambda gp: hasWordBeginningWith(sentence=gp.getFirstname(), query=self._query),
                                     reverse=True)  # rule 2), need reverse, since True > False
            self._searchResults.sort(key=lambda gp: hasWordBeginningWith(sentence=gp.getLastname(), query=self._query),
                                     reverse=True)  # rule 1), need reverse, since True > False

            self._lastChanged = datetime.now()
        finally:
            self._lock.release()

    def addCoolGuys(self):
        """
        EasterEgg, adds the cool guys to the search item
        """
        self._lock.acquire_write()
        try:
            self._searchResults.insert(0, GeneralPerson('Varsha', 'Gattu', 'Ramenator', -6))
            self._searchResults.insert(0, GeneralPerson('Serdar', 'Durdyyev', '', -5))
            self._searchResults.insert(0, GeneralPerson('Matias', 'Klimpel', 'Appreciator of Vogon Poetry', -4))
            self._searchResults.insert(0, GeneralPerson('Julien', 'Schanz', 'Smooth Operator', -3))
            self._searchResults.insert(0, GeneralPerson('Anthony', 'Heggen', 'Vampire', -2))
            self._searchResults.insert(0, GeneralPerson('Ali', 'Alhasani', 'The App Guy', -1))
            self._lastChanged = datetime.now()
        finally:
            self._lock.release()

    def addTheBoss(self):
        """
        EasterEgg, adds the boss to the search item
        """
        self._lock.acquire_write()
        try:
            self._searchResults.insert(0, GeneralPerson('Andreas', 'Zeller', 'The Boss', -7))

            self._lastChanged = datetime.now()
        finally:
            self._lock.release()

    def getQuery(self):
        """
        Getter for the query
        @return: str
        """
        self._lock.acquire_read()
        try:
            return self._query
        finally:
            self._lock.release()

    def getSearchResults(self, page: int, pageSize: int):
        """
        Getter for the search results on page with pageSize
        @param page: int
        @param pageSize: int
        @return: list of GeneralPerson
        """
        self._lock.acquire_read()
        try:
            if not hasPage(page=page, pageSize=pageSize, itemCount=self.getItemCount()):
                return []
            return self._searchResults[page*pageSize:(page+1)*pageSize]
        finally:
            self._lock.release()

    def getItemCount(self):
        """
        Returns the number of search results
        @return: int
        """
        self._lock.acquire_read()
        try:
            return len(self._searchResults)
        finally:
            self._lock.release()

    def getLastUpdated(self):
        """
        Getter for the last update time
        @return: datetime
        """
        self._lock.acquire_read()
        try:
            return self._lastChanged
        finally:
            self._lock.release()


class DirectoryCache:

    def __init__(self):
        """
        Constructor for the directory cache. The directory cache consists of a list that acts like a queue in the
        following way:
        When a entry is added, it is added at the end of the list with a timestamp.
        Every time, an update is performed, the beginning of the list is checked. Elements that have been added longer
        than a specified time ago, get removed.
        Entries consist of SearchItems
        """
        self.queue = []
        self.THRESHOLD = DIRECTORY_CACHE_THRESHOLD

    def update(self):
        """
        Updates the cache by removing old entries from the front of the queue
        """
        directoryLock.acquire_write()
        try:
            now = datetime.now()

            for searchItem in self.queue:
                if (now - searchItem.getLastUpdated()) > self.THRESHOLD:
                    self.queue.pop(0)
                else:
                    break
        finally:
            directoryLock.release()

    def addEntry(self, entry: SearchItem):
        """
        Adds entry to the cache
        @param entry: SearchItem
        """
        directoryLock.acquire_write()
        try:
            self.queue.append(entry)
        finally:
            directoryLock.release()
        self.update()

    def findEntry(self, query: str):
        """
        Finds entry in cache with query. If there is no entry with requested query, return None
        @param query: str
        @return: SearchItem or None
        """
        directoryLock.acquire_read()
        try:
            position = [item.getQuery() for item in self.queue].index(query)
            entry = self.queue[position]
            return entry
        except ValueError as e:
            return None
        finally:
            directoryLock.release()
            self.update()


class GeneralPerson:

    def __init__(self, firstname: str, lastname: str, title: str, pID: int):
        """
        Creates a general person, which has only a first and name, title and pID
        should not need a lock, since it should never be written to except for initialization
        """
        self._firstname = firstname
        self._lastname = lastname
        self._title = title
        self._pID = pID

    def getName(self) -> str:
        """
        Getter for name. Creates the entire name from first and last name
        @return: str
        """
        return self._firstname + ' ' + self._lastname

    def getFirstname(self) -> str:
        """
        Getter for the first name
        @return: str
        """
        return self._firstname

    def getLastname(self) -> str:
        """
        Getter for the last name
        @return: str
        """
        return self._lastname

    def getTitle(self) -> str:
        """
        Getter for the title
        @return: str
        """
        return self._title

    def getPID(self) -> int:
        """
        Getter for pID
        @return: int
        """
        return self._pID

    def __eq__(self, other):
        """
        Equality for GeneralPerson. other is equal to self iff their pids match
        @param other: object
        @return: bool
        """
        if not isinstance(other, GeneralPerson):
            return False

        return other.getPID() == self._pID

    def __hash__(self):
        """
        uses the pid for the hash
        @return: int
        """
        return self._pID

    def __str__(self):
        return "Name: {name}, pID: {pid}".format(name=self.getName(), pid=self._pID)


class FunctionDetails:

    def __init__(self, department: str, function: str, start: str, end: str, postalCode: str, city: str, street: str,
                 room: str, building: str, phone: str, fax: str, mail: str, webpage: str):
        self._webpage = webpage if webpage is not None else ""
        self._mail = mail if mail is not None else ""
        self._fax = fax if fax is not None else ""
        self._phone = phone if phone is not None else ""
        self._building = building if building is not None else ""
        self._room = room if room is not None else ""
        self._street = street if street is not None else ""
        self._city = city if city is not None else ""
        self._postalCode = postalCode if postalCode is not None else ""
        self._end = end if end is not None else ""
        self._start = start if start is not None else ""
        self._function = function if function is not None else ""
        self._department = department if department is not None else ""

    def getDepartment(self):
        """
        Getter for the department
        @return: str
        """
        return self._department

    def getFunction(self):
        """
        Getter for the function
        @return: str
        """
        return self._function

    def getStart(self):
        """
        Getter for start
        @return: str
        """
        return self._start

    def getEnd(self):
        """
        Getter for end
        @return: str
        """
        return self._end

    def getRoom(self):
        """
        Getter for the office.
        @return: str
        """
        return self._room

    def getBuilding(self):
        """
        Getter for the building.
        @return: str
        """
        return self._building

    def getStreet(self):
        """
        Getter for the street.
        @return: str
        """
        return self._street

    def getPostalCode(self):
        """
        Getter for the postal code
        @return: str
        """
        return self._postalCode

    def getCity(self):
        """
        Getter for the city.
        @return: str
        """
        return self._city

    def getPhone(self):
        """
        Getter for the phone
        @return: str
        """
        return self._phone

    def getFax(self):
        """
        Getter for the fax
        @return: str
        """
        return self._fax

    def getMail(self):
        """
        Getter for the mail
        @return: str
        """
        return self._mail

    def getWebpage(self):
        """
        Getter for the webpage
        @return: str
        """
        return self._webpage


class DetailedPerson:

    def __init__(self, firstname: str, lastname: str, academicTitle: str, gender: str, officeHour: str, remarks: str,
                 postalCode: str, city: str, street: str, office: str, building: str,
                 phone: str, fax: str, mail: str, webpage: str, functions: list,
                 imageLink: str = None):
        """
        should not need a lock, since it should never be written to except for initialization
        :param firstname:
        :param lastname:
        :param academicTitle:
        :param gender:
        :param officeHour:
        :param remarks:
        :param postalCode:
        :param city:
        :param street:
        :param office:
        :param building:
        :param phone:
        :param fax:
        :param mail:
        :param webpage:
        """
        self._imageLink = imageLink
        self._webpage = webpage
        self._mail = mail
        self._fax = fax
        self._phone = phone
        self._building = building
        self._office = office
        self._street = street
        self._city = city
        self._postalCode = postalCode
        self._remarks = remarks
        self._officeHour = officeHour
        self._gender = gender
        self._academicTitle = academicTitle
        self._lastname = lastname
        self._firstname = firstname
        self._functions = functions  # list of PersonFunctionDetails

        self.lock = RWLock()

    def __str__(self):
        self.lock.acquire_read()
        try:
            return "Firstname: {}\nLastname: {}\nAcademic Title: {}\nGender: {}\nOfficeHour: {}\nRemark: {}\n" \
                   "Address: {}, {}\n{}\n{} {}\nPhone: {}\nFax: {}\nE-Mail: {}\n" \
                   "Website: {}".format(self._firstname, self._lastname, self._academicTitle, self._gender,
                                        self._officeHour, self._remarks, self._office, self._building, self._street,
                                        self._postalCode, self._city, self._phone, self._fax, self._mail, self._webpage)
        finally:
            self.lock.release()

    def getFirstname(self):
        """
        Getter for the firstname.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._firstname
        finally:
            self.lock.release()

    def getLastname(self):
        """
        Getter for the lastname.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._lastname
        finally:
            self.lock.release()

    def getAcademicTitle(self):
        """
        Getter for the academic title.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._academicTitle
        finally:
            self.lock.release()

    def getGender(self, language: str):
        """
        Getter for the gender
        @param language: str
        @return: str
        """
        self.lock.acquire_read()
        try:
            if self._gender == 'männlich':
                if language == 'de':
                    return 'männlich'
                elif language == 'en':
                    return 'male'
                elif language == 'fr':
                    return 'masculin'
                else:
                    return 'männlich'
            elif self._gender == 'weiblich':
                if language == 'de':
                    return 'weiblich'
                elif language == 'en':
                    return 'female'
                elif language == 'fr':
                    return 'féminine'
                else:
                    return 'weiblich'
            else:
                if language == 'de':
                    return 'unbekannt'
                elif language == 'en':
                    return 'unknown'
                elif language == 'fr':
                    return 'inconnu'
                else:
                    return 'unbekannt'
        finally:
            self.lock.release()

    def getOfficeHour(self):
        """
        Getter for the office hour.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._officeHour
        finally:
            self.lock.release()

    def getRemark(self):
        """
        Getter for the remark.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._remarks
        finally:
            self.lock.release()

    def getOffice(self):
        """
        Getter for the office.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._office
        finally:
            self.lock.release()

    def getBuilding(self):
        """
        Getter for the building.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._building
        finally:
            self.lock.release()

    def getStreet(self):
        """
        Getter for the street.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._street
        finally:
            self.lock.release()

    def getPostalCode(self):
        """
        Getter for the postal code
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._postalCode
        finally:
            self.lock.release()

    def getCity(self):
        """
        Getter for the city.
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._city
        finally:
            self.lock.release()

    def getPhone(self):
        """
        Getter for the phone
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._phone
        finally:
            self.lock.release()

    def getFax(self):
        """
        Getter for the fax
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._fax
        finally:
            self.lock.release()

    def getMail(self):
        """
        Getter for the mail
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._mail
        finally:
            self.lock.release()

    def getWebpage(self):
        """
        Getter for the webpage
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._webpage
        finally:
            self.lock.release()

    def getFunctions(self):
        """
        Getter for the functions
        @return: list of PersonFunctionDetails
        """
        self.lock.acquire_read()
        try:
            return self._functions
        finally:
            self.lock.release()

    def getImageLink(self):
        """
        Getter for the image link
        @return: str
        """
        self.lock.acquire_read()
        try:
            return self._imageLink
        finally:
            self.lock.release()

    def setImageLink(self, link: str):
        """
        Setter for the image link
        @param link: str
        """
        self.lock.acquire_write()
        try:
            self._imageLink = link
        finally:
            self.lock.release()

    def setRemark(self, remarks: str):
        """
        Setter for the remarks
        @param remarks: str
        """
        self.lock.acquire_write()
        try:
            self._remarks = remarks
        finally:
            self.lock.release()


class HelpfulNumber:

    def __init__(self, language: str, number: str, link: str, mail: str, name: str):
        """
        Creates a helpful number.
        @param language: str, language code
        @param number: str
        @param link: str, the link
        @param mail: str, the email address
        @param name: str, the helpful number's name
        """
        self._language = language
        self._number = number
        self._link = link
        self._mail = mail
        self._name = name

    def __eq__(self, other):
        """
        Equality for HelpfulNumber holds iff all fields are the same
        @param other: object
        @return: bool
        """
        if not isinstance(other, HelpfulNumber):
            return False

        return self._language == other.getLanguage() and self._number == other.getNumber() and \
               self._link == other.getLink() and self._mail == other.getMail() and self._name == other.getMail()

    def __hash__(self):
        """
        Hash for HelpfulNumber
        @return: str
        """
        return hash(self._language) + hash(self._number) + hash(self._link) + hash(self._mail) + hash(self._name)

    def getLanguage(self):
        """
        Getter for the language
        @return: str
        """
        return self._language

    def getNumber(self):
        """
        Getter for the number
        @return: str
        """
        return self._number

    def getLink(self):
        """
        Getter for the link
        @return: str
        """
        return self._link

    def getMail(self):
        """
        Getter for the mail
        @return: str
        """
        return self._mail

    def getName(self):
        """
        Getter for the name
        @return: str
        """
        return self._name


class HelpfulNumberModel:

    def __init__(self):
        """
        Creates a new HelpfulNumberModel.
        """
        self._lastChanged = None
        self._UPDATE_THRESHOLD = timedelta(days=1)
        self._helpfulNumbers = {}  # a dict of language to list
        self._lock = RWLock()

    def update(self, helpfulNumbers: dict):
        """
        Updates the model. Checks, if there has been an actual change to set lastUpdated.
        @param helpfulNumbers: dict of language code to list of HelpfulNumbers
        """
        self._lock.acquire_write()
        try:
            updated = False
            for language in helpfulNumbers.keys():
                if language not in self._helpfulNumbers.keys():
                    # new language, there has been an actual update
                    self._helpfulNumbers[language] = helpfulNumbers[language]
                    updated = True
                else:
                    # language is known, check if the items are the same
                    if not collectionCounter(helpfulNumbers[language]) == collectionCounter(self._helpfulNumbers[language]):
                        # there is an actual update
                        self._helpfulNumbers[language] = helpfulNumbers[language]
                        updated = True

            if updated:
                self._lastChanged = datetime.now()
        finally:
            self._lock.release()

    def isUpToDate(self):
        """
        Compares the current time to the lastUpdated. If the difference exceeds a predefined threshold, return False
        @return True, if the lastUpdated time is less than self._UPDATE_THRESHOLD away from now
        """
        self._lock.acquire_read()
        try:
            if self._lastChanged is None:
                return False

            return (datetime.now() - self._lastChanged) < self._UPDATE_THRESHOLD
        finally:
            self._lock.release()

    def getHelpfulNumbers(self, language: str):
        """
        Getter for the helpful numbers in a language. If this language is not known returns German as a default
        @param language: str
        @return: list of HelpfulNumber
        """
        self._lock.acquire_read()
        try:
            if language not in self._helpfulNumbers.keys():
                return self._helpfulNumbers['de']
            else:
                return self._helpfulNumbers[language]
        finally:
            self._lock.release()

    def getLastChanged(self):
        """
        Getter for lastChanged
        @return: datetime
        """
        self._lock.acquire_read()
        try:
            return self._lastChanged
        finally:
            self._lock.release()
