from os.path import isfile, join
from os import listdir
from datetime import datetime
from source.networking.NetworkManager import NetworkManager
from source.parsers.DirectoryParser import DirectoryParser, UnspecificSearchQueryException
from source.views.DirectoryView import DirectoryView
from source.models.DirectoryModel import DirectoryCache, SearchItem, hasPage, createSecretPerson, HelpfulNumberModel
from source.Constants import HELPFUL_NUMBERS_PATH, DIRECTORY_IMAGE_PATH


def splitSearchQuery(searchQuery: str) -> list:
    """
    Takes a searchQuery and returns possible combinations of first and last names as a list of tuples.
    @param searchQuery: str
    @return: list of pairs
    """
    searchWords = searchQuery.split()
    count = len(searchWords)

    combinations = []

    for i in range(count+1):
        combinations.append((" ".join(searchWords[:i]), " ".join(searchWords[i:])))

    return combinations


class DirectoryController:

    def __init__(self, networkManager: NetworkManager):
        """
        Creates a new DirectoryController.
        """
        self._networkManager = networkManager
        self._directoryParser = DirectoryParser()
        self._directoryView = DirectoryView()
        self._directoryCache = DirectoryCache()
        self._helpfulNumberModel = HelpfulNumberModel()
        # These files have to be provided manually. The tool 'helpfulNumberWriter.py' can help with that.
        self._HELPFUL_NUMBERS_PATH = HELPFUL_NUMBERS_PATH

    def searchDirectory(self, searchQuery: str, page: int, pageSize: int, lang):
        """
        Search the directory for the searchQuery. Returns found elements on page page of size pageSize.
        If the user hasn't narrowed down his search enough i.e. there are still too many
        results, the return value will be a JSON of the form:
        "Too many results"
        Caches valid
        @param lang:
        @param searchQuery: str
        @param page: int
        @param pageSize: int
        @return: a JSON of the form { "itemCount": itemCount, "hasNextPage": hasNextPage,
                                      "results": [ { "name": name1, "title": title1, "pid": pid1 },
                                                   { "name": name2, "title": title2, "pid": pid2 }, ... ] }
                 or
                    "Too many results"
        """
        try:
            # check the cache to see if the request is already present
            cachedItem = self._directoryCache.findEntry(query=searchQuery)

            if cachedItem is not None:
                itemCount = cachedItem.getItemCount()
                resultList = cachedItem.getSearchResults(page=page, pageSize=pageSize)
                hasNextPage = hasPage(page=page + 1, pageSize=pageSize, itemCount=itemCount)
                return self._directoryView.showSearchResults(searchResultList=resultList, itemCount=itemCount,
                                                             hasNextPage=hasNextPage, lang=lang)
            else:
                searchItem = SearchItem(query=searchQuery)

                # get all combinations of search queries, request and parse the results and add them to the search item
                comb = splitSearchQuery(searchQuery)
                try:
                    for firstname, lastname in comb:
                        p = 0
                        while(True):
                            # Get results from page p
                            searchResultHTML = self._networkManager.fetchDirectorySearchResults(firstname=firstname,
                                                                                                lastname=lastname,
                                                                                                page=p, pageSize=100)

                            searchResultList, resultCount = \
                                self._directoryParser.parseWebpageForPIDs(webpage=searchResultHTML)

                            # Add the results from page p to the searchItem
                            if searchResultList is not None:
                                searchItem.update(results=searchResultList)

                            # Increase p and check if there is a next page. If not, break
                            p += 1

                            if not hasPage(page=p, pageSize=100, itemCount=resultCount):
                                break
                except UnspecificSearchQueryException as e:
                    e.query = searchQuery
                    return self._directoryView.showSearchResults(searchResultList=None, itemCount=0, hasNextPage=False,
                                                                 lang=lang)

                # sort the search item
                searchItem.sortResults()

                # easter eggs
                if searchQuery.lower() == 'cool guys':
                    searchItem.addCoolGuys()

                if searchQuery.lower() == 'the boss':
                    searchItem.addTheBoss()

                # add the item to the cache
                self._directoryCache.addEntry(entry=searchItem)

                # gather the needed information for the directory view
                itemCount = searchItem.getItemCount()
                resultList = searchItem.getSearchResults(page=page, pageSize=pageSize)
                hasNextPage = hasPage(page=page + 1, pageSize=pageSize, itemCount=itemCount)

                return self._directoryView.showSearchResults(searchResultList=resultList, itemCount=itemCount,
                                                             hasNextPage=hasNextPage, lang=lang)

        except Exception as e:
            raise e

    def showPersonDetails(self, pID: int, language: str):
        """
        Show details for a person with pID.
        @param pID: int
        @param language: str, used for fields whose value should be in the corresponding language (i.e. gender)
        @return: a JSON of the form:
        { "firstname": firstname, "lastname": lastname, "title": academicTitle, "gender": gender,
         "officeHour": officeHour, "remark": remark, "office": office, "building": building, "street": street,
         "postalCode": postalCode, "city": city, "phone": phone, "fax": fax, "mail": mail, "webpage": webpage }
        """
        if pID < 0:
            # manually added "secret" person

            if pID >= -6:
                # one of the cool guys
                person = createSecretPerson(pid=pID)
                return self._directoryView.showPersonDetails(person=person, language=language)
            if pID == -7:
                # the boss
                personDetailHTML = self._networkManager.fetchPersonDetails(pID=2307)

                theBoss = self._directoryParser.parsePersonDetail(webpage=personDetailHTML)
                theBoss.setImageLink(link='https://www.st.cs.uni-saarland.de/zeller/Zeller09-150.jpg')
                theBoss.setRemark(remarks="\"What's on the Mensa Menu today?\"")

                return self._directoryView.showPersonDetails(person=theBoss, language=language)
        else:
            try:
                personDetailHTML = self._networkManager.fetchPersonDetails(pID=pID)

                person = self._directoryParser.parsePersonDetail(webpage=personDetailHTML)

                return self._directoryView.showPersonDetails(person=person, language=language)

            except Exception as e:
                raise e

    def showImage(self, name: str):
        """
        Returns image of name name from Folder DIRECTORY_IMAGE_PATH
        @param name: str
        @return: byte
        """
        with open(join(DIRECTORY_IMAGE_PATH, name), 'rb') as f:
            image = f.read()

        return image

    def readHelpfulNumbersFiles(self, helpfulNumberPath):
        """
        Reads helpfulNumberFiles from the folder helpfulNumberPath.
        If there are several files, each one will be read.
        The files should have the following content:
            { "language": language, "numbers": [ {"number": number, "link": link, "mail": mail, "name": name}, ... ] }
        @param helpfulNumberPath: path containing the helpful number files
        @return: List of strings, each one the content of a file
        """
        # Gather all files in folder helpfulNumberPath
        fileList = [f for f in listdir(helpfulNumberPath) if isfile(join(helpfulNumberPath, f))]
        dataList = []

        for fileName in fileList:
            with open(join(helpfulNumberPath, fileName), 'r') as f:
                dataList.append(f.read())
        return dataList

    def getHelpfulNumbers(self):
        """
        Reads helpfulNumberFiles from the folder HELPFUL_NUMBER_PATH and converts them to a dictionary of language
        codes (str) to a list of HelpfulNumbers
        @return: dictionary of language (str) to list of HelpfulNumber
        """
        helpfulNumbers = {}

        # read the helpfulNumberFiles
        helpfulNumberFiles = self.readHelpfulNumbersFiles(self._HELPFUL_NUMBERS_PATH)

        # parse each helpful number file to get the language used and the HelpfulNumber lists
        for helpfulNumberJSON in helpfulNumberFiles:
            language, helpfulNumberList = self._directoryParser.parseHelpfulNumbers(helpfulNumberJSON)
            helpfulNumbers[language] = helpfulNumberList

        return helpfulNumbers

    def updateHelpfulNumbers(self):
        """
        Updates the helpful numbers in the helpfulNumbersModel
        """
        helpfulNumbers = self.getHelpfulNumbers()
        self._helpfulNumberModel.update(helpfulNumbers)

    def showHelpfulNumbers(self, language: str, lastUpdated: datetime):
        """
        Shows helpful numbers in language only iff there has been a change in the data since the client's lastUpdated
        @param language: str, language code
        @param lastUpdated: datetime, tells the server when the client has last updated his helpful numbers
        @return: JSON of the form:
            { 'numbersLastChanged': numLastChanged,
              'numbers': [ {"name": name, "number": number, "link": link, "mail": mail}, ... ] }
        where link and mail are optional or "still up to date" if the client's helpful numbers are still up to date
        """
        try:
            if (lastUpdated is None) or lastUpdated < self._helpfulNumberModel.getLastChanged():
                helpfulNumbers = self._helpfulNumberModel.getHelpfulNumbers(language=language)
                lastChanged = self._helpfulNumberModel.getLastChanged()
                return self._directoryView.showHelpfulNumbers(helpfulNumbers=helpfulNumbers,
                                                              numbersLastChanged=lastChanged)
            else:
                return self._directoryView.clientUpToDate()
        except Exception as e:
            raise e
