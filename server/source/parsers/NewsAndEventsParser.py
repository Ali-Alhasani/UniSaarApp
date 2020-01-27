import feedparser as fp
from tabula import read_pdf
import dateparser
from source.models.NewsModel import NewsModel
from dateutil import parser as dateParser
from datetime import datetime
from source.models.EventModel import EventModel
from time import mktime
from source.models.NewsFeedModel import Category
from source.Constants import *


class NewsAndEventsParser:
    def __init__(self, networkManager):
        self.networkManager = networkManager
        self.currentNewsAndEventsID = 0
        self.currentCategoryID = 6
        deEventCat = Category(GERMAN_NEWS_STRING, 0)
        enEventCat = Category(ENGLISH_NEWS_STRING, 1)
        frEventCat = Category(FRENCH_NEWS_STRING, 2)
        deNewsCat = Category(GERMAN_EVENT_STRING, 3)
        enNewsCat = Category(ENGLISH_EVENT_STRING, 4)
        frNewsCat = Category(FRENCH_EVENT_STRING, 5)
        self.languageCategories = set()
        self.allCategories = set()
        self.eventCategories = set()
        self.languageCategories.add(deNewsCat)
        self.languageCategories.add(enNewsCat)
        self.languageCategories.add(frNewsCat)
        self.languageCategories.add(deEventCat)
        self.languageCategories.add(enEventCat)
        self.languageCategories.add(frEventCat)
        self.eventCategories.add(deEventCat)
        self.eventCategories.add(enEventCat)
        self.eventCategories.add(frEventCat)
        self.allCategories.add(deNewsCat)
        self.allCategories.add(enNewsCat)
        self.allCategories.add(frNewsCat)
        self.allCategories.add(deEventCat)
        self.allCategories.add(enEventCat)
        self.allCategories.add(frEventCat)
        self.academicCalendarParsedNames = []

    def getLanguageCategories(self):
        return self.languageCategories

    def getEventCategories(self):
        """
        :return: all event categories that have been parsed with this parser
        """
        return self.eventCategories

    def getCategories(self):
        """
        :return: all categories (i.e. news and events) that have previously been parsed with this parser
        """
        return self.allCategories

    def parseNews(self, dataRSS: str, language):
        """
        parses an RSS string that is obtained from the university news rss feed and returns a
        list of NewsModel objects containing all news items given in dataRSS
        :param language:
        :param dataRSS: an rss string containing university news
        :return a list of news items
        """
        newsList = []
        rss = fp.parse(dataRSS)
        items = rss['items']
        for item in items:
            title = item['title']
            publishedDate = datetime.fromtimestamp(mktime(item['published_parsed'])).date()
            link = item['link']  # this seems to be empty in all of the uni news
            categories = set()
            category = None
            if language == 'de':
                category = Category(GERMAN_NEWS_STRING, self.currentCategoryID)
            elif language == 'en':
                category = Category(ENGLISH_NEWS_STRING, self.currentCategoryID)
            elif language == 'fr':
                category = Category(FRENCH_NEWS_STRING, self.currentCategoryID)
            if category is not None:
                for cat in self.allCategories:
                    if cat == category:
                        categories.add(cat)
                if category not in categories:
                    categories.add(category)
            for tag in item['tags']:
                category = Category(tag['term'], self.currentCategoryID)
                # Category.__eq__ is implemented via equality of the name string
                # thus, if category is already in allCategories, this will only keep the
                # category with the smaller id
                for cat in self.allCategories:
                    if cat == category:
                        categories.add(cat)
                if category not in categories:
                    categories.add(category)
                if category not in self.allCategories:
                    self.allCategories.add(category)
                    self.currentCategoryID += 1
            description = item['description']
            content = item['content'][0]['value'].strip()
            imageLink = None
            for potentialImageLink in item['links']:
                if 'image' in potentialImageLink['type']:
                    imageLink = potentialImageLink['href']
            #link = ""
            newsItem = NewsModel(title, publishedDate, self.currentNewsAndEventsID, link, categories, description, content, imageLink)
            newsList.append(newsItem)
            self.currentNewsAndEventsID = self.currentNewsAndEventsID + 1
        return newsList

    def parseEvents(self, dataRSS: str, language):
        """
        parses an RSS string that is obtained from the university events rss feed and returns a
        list of EventModel objects containing all news items given in dataRSS
        :param dataRSS: an rss string containing university events
        :return a list of events items
        """
        eventsList = []
        rss = fp.parse(dataRSS)
        items = rss['items']
        for item in items:
            title = item['title']
            publishedDate = datetime.now().date()
            happeningTime = dateParser.parse(item['published'])
            happeningDate = happeningTime.date()
            link = item['link']  # this seems to be empty in all of the uni events
            categories = set()
            category = None
            if language == 'de':
                category = Category(GERMAN_EVENT_STRING, self.currentCategoryID)
            elif language == 'en':
                category = Category(ENGLISH_EVENT_STRING, self.currentCategoryID)
            elif language == 'fr':
                category = Category(FRENCH_EVENT_STRING, self.currentCategoryID)
            if category is not None:
                for cat in self.allCategories:
                    if cat == category:
                        categories.add(cat)
                        if cat not in self.eventCategories:
                            self.eventCategories.add(cat)
                if category not in categories:
                    categories.add(category)
                if category not in self.allCategories:
                    self.allCategories.add(category)
                    self.currentCategoryID += 1
                if category not in self.eventCategories:
                    self.eventCategories.add(category)
                    self.currentCategoryID += 1
            for tag in item['tags']:
                category = Category(tag['term'], self.currentCategoryID)
                # Category.__eq__ is implemented via equality of the name string
                # thus, if category is already in allCategories, this will only keep the
                # category with the smaller id
                for cat in self.allCategories:
                    if cat == category:
                        categories.add(cat)
                        self.eventCategories.add(cat)
                if category not in categories:
                    categories.add(category)
                if category not in self.allCategories:
                    self.allCategories.add(category)
                    self.eventCategories.add(category)
                    self.currentCategoryID += 1
                if category not in self.eventCategories:
                    self.eventCategories.add(category)
            description = item['description']
            content = item['content'][0]['value'].strip()

            imageLink = None
            for potentialImageLink in item['links']:
                if 'image' in potentialImageLink['type']:
                    imageLink = potentialImageLink['href']
            #link = ""
            eventItem = EventModel(title, happeningDate, publishedDate, self.currentNewsAndEventsID, link, categories,
                                   description, content, imageLink, happeningTime)
            eventsList.append(eventItem)
            self.currentNewsAndEventsID = self.currentNewsAndEventsID + 1
        return eventsList

    def parseAcademicCalendarPDF(self, filePath):
        """
        parses a pdf file as provided by the uds in which there are all dates of
        :param filePath: the path to the pdf to be parsed
        :return: a list of events containing the dates of the academic year
        """
        dateTable = read_pdf(filePath, silent=True)  # returns a data frame object with the dates of the academic year
        eventList = []
        semTemCat = Category(SEMESTER_TERMINE_CATEGORY_STRING, self.currentCategoryID)
        self.currentCategoryID += 1
        for cat in self.eventCategories:
            if cat == semTemCat:
                semTemCat = cat
        if semTemCat not in self.eventCategories:
            self.eventCategories.add(semTemCat)
        # the first of these entries is interpreted as a title for the columns of the table
        # hence this weird workaround
        eventList.append(
            EventModel(dateTable.columns[0].replace('\r', ' '), dateparser.parse(dateTable.columns[1]).date(),
                       datetime.now().date(), self.currentNewsAndEventsID, SEMESTER_TERMINE_LINK, [semTemCat], '', ''))
        self.currentNewsAndEventsID += 1
        shape = dateTable.shape
        # now, look at the rest of the table and add an event for every row
        for i in range(shape[0]):
            happeningDate = dateparser.parse(dateTable.iat[i, 1])
            if happeningDate is None:
                continue
            eventList.append(
                EventModel(dateTable.iat[i, 0].replace('\r', ' '), happeningDate.date(), datetime.now().date(),
                           self.currentNewsAndEventsID, SEMESTER_TERMINE_LINK, [semTemCat], '', ''))
            self.currentNewsAndEventsID += 1
        return eventList

    def readAcademicCalendarEvents(self):
        """
        calls the methods to download all academic calendar pdfs and then the one to parse all of the new ones
        :return: returns events for each event noted in the pdfs
        """
        pdfNames = self.networkManager.getAcademicCalendarPDFFiles()
        events = []
        for name in pdfNames:
            if name not in self.academicCalendarParsedNames:
                events += self.parseAcademicCalendarPDF(name)
                self.academicCalendarParsedNames.append(name)
        return events

