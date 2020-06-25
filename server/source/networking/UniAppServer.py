from http.server import ThreadingHTTPServer
from datetime import datetime
from source.controller.DirectoryController import DirectoryController
from source.controller.MapController import MapController
from source.controller.MensaController import MensaController
from source.controller.MoreController import MoreController
from source.controller.NewsFeedController import NewsFeedController


class UniAppServer(ThreadingHTTPServer):

    def __init__(self, serverAddress, RequestHandlerClass, networkManager):

        self.mensaController = MensaController(networkManager)
        self.newsFeedController = NewsFeedController(networkManager)
        self.moreController = MoreController()
        self.directoryController = DirectoryController(networkManager)
        self.mapController = MapController()
        self.networkManager = networkManager
        super().__init__(serverAddress, RequestHandlerClass)
        print("server is running...")

    def updateHelpfulNumbers(self):
        self.directoryController.updateHelpfulNumbers()

    def updateMensa(self):
        self.mensaController.updateMensa()

    def updateNewsFeed(self):
        self.newsFeedController.updateNewsFeed()

    def updateMap(self):
        self.mapController.updateMap()

    def requestMap(self, lastUpdateTime=None):
        return self.mapController.retrieveMap(lastUpdateTime)

    def requestMensaMainScreen(self, locationID, language, date):
        return self.mensaController.showMensaMainScreen(locationID=locationID, language=language, date=date)

    def requestMensaDetailScreen(self, mealID, language):
        return self.mensaController.showMensaDetailScreen(mealID=mealID, language=language)

    def requestMensaInfo(self, locationID, language):
        return self.mensaController.showMensaInfo(locationID=locationID, language=language)

    def requestMensaFilters(self, language):
        return self.mensaController.showMensaFilters(language=language)

    def requestNewsFeedMainScreen(self, page, pageSize, language, filterIDs=None, negFilterIDs=None):
        return self.newsFeedController.showNewsFeedMainScreen(page, pageSize, language, filterIDs, negFilterIDs)

    def requestNewsDetails(self, newsItemID, language):
        return self.newsFeedController.showsNewsItemDetails(newsItemID, language)

    def requestEventDetails(self, eventItemID, language):
        return self.newsFeedController.showEventItemDetails(eventItemID, language)

    def requestEventICal(self, eventID):
        return self.newsFeedController.showEventICal(eventID)

    def requestEvents(self, year, month, language, filterIDs=None, negFilterIDs=None):
        return self.newsFeedController.showEvents(year, month, language, filterIDs, negFilterIDs)

    def requestNewsFeedCategories(self, language):
        return self.newsFeedController.showCategories(language)

    def requestEventCategories(self, language):
        return self.newsFeedController.showEventCategories(language)

    def searchDirectory(self, searchQuery: str, page: int, pageSize: int):
        return self.directoryController.searchDirectory(searchQuery=searchQuery,
                                                        page=page, pageSize=pageSize)

    def requestPersonDetails(self, pID: int, language: str):
        return self.directoryController.showPersonDetails(pID=pID, language=language)

    def showImage(self, name: str):
        return self.directoryController.showImage(name=name)

    def showHelpfulNumbers(self, language: str, lastUpdated: datetime):
        return self.directoryController.showHelpfulNumbers(language=language, lastUpdated=lastUpdated)
    
    def requestMore(self, language, time):
        return self.moreController.retrieveMore(language, time)

    def requestErrorPage(self, language):
        return self.newsFeedController.showErrorPage(language=language)
