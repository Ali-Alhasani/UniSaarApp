from source.models.NewsFeedModel import NewsFeedModel, NonexistentIDError
from source.views.NewsFeedView import NewsFeedView
from source.networking.NetworkManager import NetworkManager
from source.parsers.NewsAndEventsParser import NewsAndEventsParser
from source.models.NewsModel import NewsModel
from source.models.EventModel import EventModel
from source.Constants import NEWSFEED_LANGUAGES


class NewsFeedController:
    def __init__(self, networkManager: NetworkManager):
        self.networkManager = networkManager
        self.newsFeedModel = NewsFeedModel([], [])
        self.newsFeedView = NewsFeedView()
        self.newsAndEventsParser = NewsAndEventsParser(networkManager)

    def requestData(self):
        """
        requests data from the news and the events api in german, english and french
        :return: dictionaries from language code to lists of NewsModels respectively EventModels
        """
        newsRaw = {'de': self.networkManager.fetchNews('de'), 'en': self.networkManager.fetchNews('en'),
                   'fr': self.networkManager.fetchNews('fr')}
        eventsRaw = {'de': self.networkManager.fetchEvents('de'), 'en': self.networkManager.fetchEvents('en'),
                     'fr': self.networkManager.fetchEvents('fr')}
        news = {}
        events = {}
        categories = {}
        eventCategories = {}
        for language in ['de', 'en', 'fr']:
            news[language] = self.newsAndEventsParser.parseNews(newsRaw[language], language)
            events[language] = self.newsAndEventsParser.parseEvents(eventsRaw[language], language)
            categories[language] = self.newsAndEventsParser.getCategories()
            eventCategories[language] = self.newsAndEventsParser.getEventCategories()
        events['de'] += self.newsAndEventsParser.readAcademicCalendarEvents()
        return news, events, categories, eventCategories

    def updateNewsFeed(self):
        """
        Access the data on a request to the network manager and pass to newsfeedmodel
        """
        try:
            news, events, categories, eventCategories = self.requestData()
            for language in NEWSFEED_LANGUAGES:
                self.newsFeedModel.update(news[language], events[language], categories[language],
                                          eventCategories[language], language=language)
        except Exception as e:
            print("there was a problem while updating the news feed")
            raise e

    def showNewsFeedMainScreen(self, page, pageSize, language, filterIDs = None, negFilterIDs=None):
        """
        returns a json containing the newsfeed after applying filters
        @param negFilterIDs: the category-ids which should be filtered out
        @param filterIDs: category-ids s.t. only items with at least one of these ids are returned
        @param language: the language for which to return the newsfeed. if language != 'de' and there are no items
            to return, returns the newsfeed for language = 'de'
        @param pageSize: number of items per page
        @param page: the number of the page to display, starting at 0
        """
        try:
            newsFeedPage, item_count, hasNextPage = self.newsFeedModel.getNewsFeed(page, pageSize,
                                                                                   language, filterIDs, negFilterIDs)
            if language != 'de' and item_count == 0:
                newsFeedPage, item_count, hasNextPage = self.newsFeedModel.getNewsFeed(page, pageSize,
                                                                                       'de', filterIDs,
                                                                                       negFilterIDs)
            returnJSON = self.newsFeedView.newsFeedHeadersToJSON(newsFeedPage,
                                                                 item_count,
                                                                 self.newsFeedModel.getCategoriesLastChanged(),
                                                                 hasNextPage)
            return returnJSON
        except Exception as e:
            print("there was a problem when retrieving the news feed main screen")
            raise e

    def showsNewsItemDetails(self, newsItemID, language):
        try:
            newsItem = self.newsFeedModel.getNewsItemByID(newsItemID)
            if isinstance(newsItem, NewsModel):
                return self.newsFeedView.toWebViewNewsItem(newsItem)
            elif isinstance(newsItem, EventModel):
                return self.newsFeedView.toWebViewEventItem(newsItem, language)
        except NonexistentIDError as e:
            print("id not in newslist: " + str(e.id))
            raise e

    def showEventItemDetails(self, eventItemID, language):
        try:
            eventItem = self.newsFeedModel.getEventItemByID(eventItemID)
            return self.newsFeedView.toWebViewEventItem(eventItem, language)
        except NonexistentIDError as e:
            print("id not in newslist: " + str(e.id))
            raise e

    def showEventICal(self, eventItemID):
        try:
            eventItem = self.newsFeedModel.getEventItemByID(eventItemID)
            return self.newsFeedView.toICalEvent(eventItem)
        except NonexistentIDError as e:
            print("id not in newslist: " + str(e.id))
            raise e

    def showEvents(self, year, month, language, filterIDs=None, negFilterIDs=None):
        """
        returns a json containing the events happening in the given month after applying filters
        :param year: the year to consider
        :param month: the month to consider
        :param language: the language for which to return the events. if language != 'de' and there are no items
            to return, returns the events for language = 'de'
        :param filterIDs: positive filters to apply to the events (all events with categories given by at least one
            filter will be returned)
        :param negFilterIDs: negative filters to apply to the events (only events with no category given by the
            negFilterIDs will be returned)
        :return a json containing the events
        """
        try:
            returnEvents = self.newsFeedModel.getEvents(year, month, language, filterIDs, negFilterIDs)
            if language != 'de' and len(returnEvents) == 0:
                returnEvents = self.newsFeedModel.getEvents(year, month, 'de', filterIDs, negFilterIDs)
            returnEventsJSON = self.newsFeedView.toJSONEvents(returnEvents, self.newsFeedModel.getEventCategoriesLastChanged())
            return returnEventsJSON
        except Exception as e:
            print("there was a problem while retrieving events")
            raise e

    def showCategories(self, language):
        categories = self.newsFeedModel.getCategories(language)
        if language != 'de' and len(categories) == 0:
            categories = self.newsFeedModel.getCategories('de')
        return self.newsFeedView.toJSONCategories(categories)

    def showEventCategories(self, language):
        categories = self.newsFeedModel.getEventCategories(language)
        if language != 'de' and len(categories) == 0:
            categories = self.newsFeedModel.getEventCategories('de')
        return self.newsFeedView.toJSONCategories(categories)

    def showErrorPage(self, language):
        """
        Shows the html error page.
        @param language: str
        """
        return self.newsFeedView.toWebViewError(language=language)
