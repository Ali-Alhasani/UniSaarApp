from datetime import datetime
from source.models.EventModel import EventModel
from source.models.NewsAndEventsModel import NewsAndEventsModel
from typing import List
from source.ReadWriteLock import RWLock
from source.Constants import SEMESTER_TERMINE_CATEGORY_STRING, NEWSFEED_UPDATE_INTERVAL_IN_SECONDS
import copy
from source.models.CategoryModel import Category

newsFeedLock = RWLock()


class NewsFeedModel:

    def __init__(self, newsAndEvents: List[NewsAndEventsModel],
                 events: List[EventModel], lastUpdated=datetime(1970, 1, 1, 0, 0, 0)):
        """
        :param newsAndEvents: a dictionary from a language code (as string) to a list of NewsAndEventModels
        :param events: a dictionary from a language code (as string) to a list of EventModels
        :param lastUpdated: a datetime object indicating, when the data stored in the model was fetched
        """
        self.newsAndEvents = newsAndEvents
        self.events = events
        self.lastUpdated = lastUpdated
        self.categories = {'lastChange': datetime.now(), 'categories': []}
        self.eventCategories = {'lastChange': datetime.now(), 'categories': []}

    def pageExists(self, itemList, page, pageSize):
        newsFeedLock.acquire_read()
        try:
            return (len(itemList) - 1) >= page * pageSize
        finally:
            newsFeedLock.release()

    def getNewsFeed(self, page, pageSize, language='de', filterIDs=None, negFilterIDs=None):
        """
        returns the items [page * pageSize, ... , (page + 1) * pageSize - 1] of the
        news and events stored in this news feed as a list
        if there are not enough items, an empty list will be returned
        if page * pageSize <= # items -1 < (page + 1) * pageSize -1, it returns the items
        [page * pageSize, ... , # items - 1]
        assumes the internal newsAndEvents are sorted such that the newest item is at position 0
        :param negFilterIDs: negated filter IDs, i.e. only items that do not belong to any category specified
                by negFilterIDs are returned
                (negFilterIDs = [id1, id2] corresponds to (NOT id1) AND (NOT id2)).
        :param filterIDs: IDs by which the news feed is to be filtered, they are implicitly joined by a OR, i.e.
                if multiple filters f1 and f2 are given, every item that belongs to f1 OR f2 is returned
                (filterIDs = [id1, id2] corresponds to id1 OR id2)
        if both filterIDs and negFilterIDs are given, only items that satisfy
                exists (catID1 IN item.categories) s.t. catID1 IN filterIDs AND
                forall (catID IN item.categories) catID NOT IN negFilterIDs
        :param language: the language for which to return the news feed
        :returns a list of newsAndEventsModels corresponding to page *page* of the news feed, the total number
                of items fitting the filters and a boolean, whether a next page exists
        :param page: the page to display, indexes start at 0
        :param pageSize: the number of entries to display per page
        """

        newsFeedLock.acquire_read()
        try:
            if (filterIDs is None) and (negFilterIDs is None):
                if not self.pageExists(self.newsAndEvents, page, pageSize):
                    # raise PageIndexOutOfRangeError(page, pageSize, self, language)
                    # return empty list instead of raising an exception
                    return [], len(self.newsAndEvents), False
                hasNextPage = self.pageExists(self.newsAndEvents, (page+1), pageSize)
                return self.newsAndEvents[page * pageSize:(page + 1) * pageSize],\
                       len(self.newsAndEvents), hasNextPage
            else:
                preFilteredNewsAndEvents = []
                filteredNewsAndEvents = []
                if filterIDs is not None:
                    for item in self.newsAndEvents:
                        catIDs = []
                        for cat in item.getCategories():
                            catIDs.append(cat.getID())
                        for filterID in filterIDs:
                            if filterID in catIDs:
                                preFilteredNewsAndEvents.append(item)
                                break
                else:
                    preFilteredNewsAndEvents = self.newsAndEvents
                if negFilterIDs is not None:
                    for item in preFilteredNewsAndEvents:
                        catIDs = []
                        keepBool = False
                        itemCopy = copy.copy(item)
                        for cat in item.getCategories():
                            catIDs.append(cat.getID())
                        for catID in catIDs:
                            if catID not in negFilterIDs:
                                keepBool = True
                            else:
                                itemCopy.removeCategories([self.getCategoryByID(catID)])
                        if keepBool:
                            filteredNewsAndEvents.append(itemCopy)
                else:
                    filteredNewsAndEvents = preFilteredNewsAndEvents
                if not self.pageExists(filteredNewsAndEvents, page, pageSize):
                    # raise PageIndexOutOfRangeError(page, pageSize, self, language, filterIDs, negFilterIDs)
                    # return empty list instead of raising an exception
                    return [], len(filteredNewsAndEvents), False
                hasNextPage = self.pageExists(filteredNewsAndEvents, page+1, pageSize)
                return filteredNewsAndEvents[page * pageSize:(page + 1) * pageSize], len(filteredNewsAndEvents), hasNextPage
        finally:
            newsFeedLock.release()

    def getEvents(self, year: int, month: int, language='de', filterIDs=None, negFilterIDs=None):
        newsFeedLock.acquire_read()
        try:
            returnEvents = []
            for event in self.events:
                happeningDate = event.getHappeningDate()
                if happeningDate.year == year and happeningDate.month == month:
                    returnEvents.append(event)
            if (filterIDs is None) and (negFilterIDs is None):
                return returnEvents
            else:
                preFilteredEvents = []
                filteredEvents = []
                if filterIDs is not None:
                    for event in returnEvents:
                        catIDs = []
                        for cat in event.getCategories():
                            catIDs.append(cat.getID())
                        for filterID in filterIDs:
                            if filterID in catIDs:
                                preFilteredEvents.append(event)
                                break
                else:
                    preFilteredEvents = returnEvents
                if negFilterIDs is not None:
                    for item in preFilteredEvents:
                        catIDs = []
                        keepBool = False
                        itemCopy = copy.copy(item)
                        for cat in item.getCategories():
                            catIDs.append(cat.getID())
                        for catID in catIDs:
                            if catID not in negFilterIDs:
                                keepBool = True
                            else:
                                itemCopy.removeCategories([self.getEventCategoryByID(catID)])
                        if keepBool:
                            filteredEvents.append(itemCopy)
                else:
                    filteredEvents = preFilteredEvents
                return filteredEvents
        finally:
            newsFeedLock.release()

    def applyNegFilter(self, preFilteredEvents, negFilterIDs):
        filteredEvents = []
        for item in preFilteredEvents:
            catIDs = []
            keepBool = False
            itemCopy = copy.copy(item)
            for cat in item.getCategories():
                catIDs.append(cat.getID())
            for catID in catIDs:
                if catID not in negFilterIDs:
                    keepBool = True
                else:
                    itemCopy.removeCategories([self.getCategoryByID(catID)])
            if keepBool:
                filteredEvents.append(itemCopy)
        return filteredEvents

    def update(self, news, events, categories, eventCategories, updateTime=datetime.now(), language='de'):
        """
        given a list of all news and events in the language indicated by the parameter 'language'
        as parsed from the rss feed, adds all new news and events to the internally stored news and events
        :param eventCategories:
        :param language: the language in which the news and the events are
        this is no longer used, since language is now a category of the individual items
        for compatibility reasons, this is for now not removed from here
        :param news: the news list with which to update the news feed
        :param events: the events list with which to update the news feed
        :param categories: the set of categories of the news
        :param updateTime: the time at which the data of this update was retrieved, now by default
        """
        newsFeedLock.acquire_write()
        try:
            self.lastUpdated = updateTime
            if self.categories['categories'] != categories:
                # if the categories change, enter now() as last changed time
                # in order to support caching on the app side
                self.categories['lastChange'] = datetime.now()
                self.categories['categories'] = categories

            if self.eventCategories['categories'] != eventCategories:
                # if the categories change, enter now() as last changed time
                # in order to support caching on the app side
                self.eventCategories['lastChange'] = datetime.now()
                self.eventCategories['categories'] = eventCategories

            for newsItem in news:
                if newsItem not in self.newsAndEvents:
                    self.newsAndEvents.append(newsItem)
            for event in events:
                semTemCat = Category(SEMESTER_TERMINE_CATEGORY_STRING, -1)
                if event not in self.newsAndEvents and (semTemCat not in event.getCategories()):
                    self.newsAndEvents.append(event)
                if event not in self.events:
                    self.events.append(event)
            self.newsAndEvents = sorted(self.newsAndEvents, reverse=True)
            self.events = sorted(self.events, key=(lambda e: e.getHappeningDate()), reverse=True)
        finally:
            newsFeedLock.release()

    def isUpToDate(self):
        """
        :returns True, if now - updateTime < UPDATE_INTERVAL, else False
        """
        newsFeedLock.acquire_read()
        try:
            now = datetime.now()
            passedTime = now - self.lastUpdated
            return passedTime < NEWSFEED_UPDATE_INTERVAL_IN_SECONDS
        finally:
            newsFeedLock.release()

    def getNewsItemByID(self, id):
        newsFeedLock.acquire_read()
        try:
            for newsItem in self.newsAndEvents:
                if newsItem.getID() == id:
                    return newsItem
            raise NonexistentIDError(id, self)
        finally:
            newsFeedLock.release()

    def getEventItemByID(self, id):
        newsFeedLock.acquire_read()
        try:
            for eventItem in self.events:
                if eventItem.getID() == id:
                    return eventItem
            raise NonexistentIDError(id, self)
        finally:
            newsFeedLock.release()

    def getCategoryByID(self, id):
        newsFeedLock.acquire_read()
        try:
            for cat in self.categories['categories']:
                if cat.getID() == id:
                    return cat
            raise NonexistentIDError(id, self)
        finally:
            newsFeedLock.release()

    def getEventCategoryByID(self, id):
        newsFeedLock.acquire_read()
        try:
            for cat in self.eventCategories['categories']:
                if cat.getID() == id:
                    return cat
            raise NonexistentIDError(id, self)
        finally:
            newsFeedLock.release()

    def getCategories(self, language):
        newsFeedLock.acquire_read()
        try:
            return self.categories['categories']
        finally:
            newsFeedLock.release()

    def getEventCategories(self, language):
        newsFeedLock.acquire_read()
        try:
            cats = self.eventCategories['categories']
            return cats
        finally:
            newsFeedLock.release()

    def getCategoriesLastChanged(self):
        newsFeedLock.acquire_read()
        try:
            return self.categories["lastChange"]
        finally:
            newsFeedLock.release()

    def getEventCategoriesLastChanged(self):
        newsFeedLock.acquire_read()
        try:
            return self.eventCategories["lastChange"]
        finally:
            newsFeedLock.release()



class NonexistentIDError(Exception):
    def __init__(self, id, newsFeed):
        self.id = id
        self.newsFeed = newsFeed


class PageIndexOutOfRangeError(Exception):
    def __init__(self, page, pageSize, newsFeed, language, filterIDs=None, negFilterIDs=None):
        self.page = page
        self.newsFeed = newsFeed
        self.language = language
        self.pageSize = pageSize
        self.filterID = filterIDs
        self.negFilterIDs = negFilterIDs
