from os.path import isfile, join
from os import listdir
from source.models.MensaModel import MensaModel
from source.views.MensaView import MensaView
from source.parsers.MensaParser import MensaParser
from source.Constants import LOCATION_INFO_PATH, MENSA_LANGUAGES


class MensaController:

    def __init__(self, networkManager):
        """
        Creates a new MensaController object. The controller has access to the Mensa model and view and is the access
        point for outside actors to get the mensa data. It is also responsible for updating the Mensa model.
        """
        self.mensaModel = MensaModel()
        self.mensaView = MensaView()
        self.mensaParser = MensaParser(mensaModel=self.mensaModel)
        self.networkManager = networkManager
        # the folder containing location info files, relative path from the folder containing main.py
        # These files have to be provided manually. The tool 'locationInfoWriter.py' can help with that.
        self.LOCATION_INFO_PATH = LOCATION_INFO_PATH
        # a list of language codes in which the Mensa Data is attempted to be retrieved
        self.LANGUAGES = MENSA_LANGUAGES

    def requestData(self, language: str):
        """
        Requests mensa data from the networkManager
        @param language: string, a language code
        """
        baseData = self.networkManager.fetchMensaBaseData(language=language)
        parsedBaseData = self.mensaParser.parseBaseData(baseData)

        menuDict = {}  # holds keys locationID and values location menu
        for location in parsedBaseData['locations']:
            menuData = self.networkManager.fetchMensaMenu(location.getID(), language=language)
            parsedMenuData = self.mensaParser.parseMenuData(menuData)
            menuDict[location.getID()] = parsedMenuData

        return parsedBaseData, menuDict

    def readLocationInfoFiles(self, locationPath):
        """
        Reads locationInfoFiles from the folder locationPath
        If there are several files, each one will be read.
        The files should have the following content:
            { "id": locationID, "name": locationName, "description": locationDescription, "link": locationImageLink }
        @param locationPath: path containing the location info files
        @return: List of strings, each one the content of a file
        """
        # Gather all files in folder locationPath
        fileList = [f for f in listdir(locationPath) if isfile(join(locationPath, f))]
        dataList = []

        for fileName in fileList:
            with open(join(locationPath, fileName), 'r') as f:
                dataList.append(f.read())

            if not f.closed:
                raise IOError

        return dataList

    def getLocationInfo(self):
        """
        Reads locationInfoFiles from the folder locationPath and converts them to a dictionary of language codes (str)
        to a dictionary with keys locationID (str) and value locationInfo (LocationInfo)
        @return: dictionary of language (str) to (dictionary of locationID (str) to locationInfo (LocationInfo))
        """
        # get list of location info strings from files in LOCATION_INFO_PATH
        infoList = self.readLocationInfoFiles(self.LOCATION_INFO_PATH)
        # parse each location info string to get dictionaries of language to LocationInfo objects
        parsedInfoDictList = [self.mensaParser.parseLocationInfo(locationInfoString) for locationInfoString in infoList]
        # create dictionary the method mensaModel.updateLocationInfo expects, i.e. a dictionary of languages to
        # a dictionary of locationID to locationInfo
        locationInfoDict = {}
        for parsedInfoDict in parsedInfoDictList:
            for language, locationInfo in parsedInfoDict.items():
                if language in locationInfoDict.keys():
                    # the dictionary of locationID to locationInfo exists already, add another key-value-pair
                    locationInfoDict[language][locationInfo.getID()] = locationInfo
                else:
                    # this is the first time a locationInfo is added in this language, hence create the dictionary
                    locationInfoDict[language] = {locationInfo.getID(): locationInfo}

        return locationInfoDict

    def updateMensa(self):
        for language in self.LANGUAGES:
            baseData, menuData = self.requestData(language=language)
            self.mensaModel.update(baseData=baseData, menuData=menuData, language=language)

        # handle the location info separately, since the data is gathered from a different source and contains all
        # available data
        locationInfoData = self.getLocationInfo()
        self.mensaModel.updateLocationInfo(locationInfo=locationInfoData)

    def showMensaMainScreen(self, locationID, language, date):
        """
        This method returns the locationID from the MensaModel. If there is no location, it throws an exception saying
        that there is an error in location
        """
        try:
            return self.mensaView.mensaMainScreenJSON(mensaModel=self.mensaModel, locationID=locationID,
                                                      language=language, date=date)
        except Exception as e:
            raise e

    def showMensaDetailScreen(self, mealID, language):
        try:
            return self.mensaView.mealDetailToJSON(mensaModel=self.mensaModel, mealID=mealID, language=language)
        except Exception as e:
            raise e

    def showMensaInfo(self, locationID, language):
        try:
            return self.mensaView.mensaInfoToJSON(mensaModel=self.mensaModel, locationID=locationID, language=language)
        except Exception as e:
            raise e

    def showMensaFilters(self, language):
        try:
            return self.mensaView.mensaFilterToJSON(mensaModel=self.mensaModel, language=language)

        except Exception as e:
            raise e

