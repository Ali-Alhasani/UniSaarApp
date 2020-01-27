import unittest
import feedparser as fp
from os.path import join
from datetime import datetime
from dateutil import parser as dateParser
from source.parsers.NewsAndEventsParser import NewsAndEventsParser
from source.models.NewsModel import NewsModel
from source.models.NewsFeedModel import Category
from source.models.EventModel import EventModel
from source.networking.NetworkManager import NetworkManager

TEST_DIRECTORY = 'testdata/newsAndEvents'
NEWSFEED_FILE = 'newsfeed.xml'
EVENTSFEED_FILE = 'eventsfeed.xml'
EXAMPLE_NEWSFEED_FILE = 'exampleNewsfeed.xml'
EXAMPLE_EVENTSFEED_FILE = 'exampleEventsfeed.xml'
EMPTY_NEWSFEED_FILE = 'emptyNewsfeed.xml'
EMPTY_EVENTSFEED_FILE = 'emptyEventsfeed.xml'
CATEGORY_NEWSFEED_FILE = 'categoryNewsfeed.xml'
NEWS_CONTENT_FILE = 'newsContent.xml'
EVENT_CONTENT_FILE = 'eventContent.xml'


class NewsAndEventsParserUnitTest(unittest.TestCase):

    def setUp(self) -> None:
        self.maxDiff = None
        self.nm = NetworkManager()
        self.parser = NewsAndEventsParser(self.nm)

        # read files containing news and eventsfeed
        with open(join(TEST_DIRECTORY, NEWSFEED_FILE), 'r') as f:
            self.newsfeed = f.read()

        with open(join(TEST_DIRECTORY, EVENTSFEED_FILE), 'r') as f:
            self.eventsfeed = f.read()

        with open(join(TEST_DIRECTORY, EXAMPLE_NEWSFEED_FILE), 'r') as f:
            self.exampleNewsfeed = f.read()

        with open(join(TEST_DIRECTORY, EXAMPLE_EVENTSFEED_FILE), 'r') as f:
            self.exampleEventfeed = f.read()

        with open(join(TEST_DIRECTORY, EMPTY_NEWSFEED_FILE), 'r') as f:
            self.emptyNewsfeed = f.read()

        with open(join(TEST_DIRECTORY, EMPTY_EVENTSFEED_FILE), 'r') as f:
            self.emptyEventfeed = f.read()

        with open(join(TEST_DIRECTORY, CATEGORY_NEWSFEED_FILE), 'r') as f:
            self.categoryNewsfeed = f.read()

        # setup constants for comparison
        with open(join(TEST_DIRECTORY, NEWS_CONTENT_FILE), 'r') as f:
            self.NEWS_ITEM_0_CONTENT = f.read()

        with open(join(TEST_DIRECTORY, EVENT_CONTENT_FILE), 'r') as f:
            self.EVENT_ITEM_1_CONTENT = f.read()

    def test_parseNewsLength(self):
        """
        Tests if the number of entries in the newsfeed are the same before and after parsing
        """
        newsList = self.parser.parseNews(self.newsfeed, 'de')
        fpNewsList = fp.parse(self.newsfeed).entries

        self.assertEqual(len(newsList), len(fpNewsList))

    def test_parseEventsLength(self):
        """
        Tests if the number of entries in the eventsfeed are the same before and after parsing
        """
        eventsList = self.parser.parseEvents(self.eventsfeed, 'de')
        fpEventsList = fp.parse(self.eventsfeed).entries

        self.assertEqual(len(eventsList), len(fpEventsList))

    def test_newsDetails(self):
        """
        Tests if the details of a news item are correctly read
        """
        newsList = self.parser.parseNews(self.newsfeed, 'de')

        newsItem = newsList[0]
        newsItemNoImage = newsList[1]

        # type
        self.assertIsInstance(newsItem, NewsModel, "News item not of type NewsModel")
        for news in newsList:
            self.assertIsInstance(news, NewsModel, "News item not of type NewsModel")

        # title
        self.assertEqual(newsItem.getTitle(), "Studie zeigt, wie Immunzellen Krankheitserreger einfangen",
                         "Title incorrectly parsed")

        # published date
        self.assertEqual(dateParser.parse("Thu, 02 Jan 2020 14:18:58 +0100").date(), newsItem.getPublishedDate(),
                         "Published date incorrectly parsed")

        # description
        self.assertEqual("Immunzellen sind ständig unterwegs, um Krankheitserreger "
                           "abzufangen. In der Haut sind dies insbesondere so genannte "
                           "dendritische Zellen, die sich viel schneller als andere "
                           "Körperzellen durch die Zellschichten bewegen. Wie die Zellen "
                           "dies genau bewerkstelligen, war bisher unerforscht. "
                           "Biophysiker um Professorin Franziska Lautenschläger haben nun "
                           "herausgefunden, wie die Fortbewegung der Abwehrzellen "
                           "funktioniert. Ihre Erkenntnisse haben sie im renommierten "
                           "Fachmagazin PNAS publiziert.",
                         newsItem.getDescription(),
                         "Description incorrectly parsed")

        # content
        self.assertEqual(self.NEWS_ITEM_0_CONTENT.strip(), newsItem.getContent().strip(), "Content incorrectly parsed")

        # categories
        self.assertIsInstance(newsItem.getCategories(), list,
                              "getCategories returns type {} instead of list".format(type(newsItem.getCategories())))
        self.assertEqual(4, len(newsItem.getCategories()),
                         "Expected 4 categories, got {}".format(len(newsItem.getCategories())))

        for category in newsItem.getCategories():
            self.assertIsInstance(category, Category,
                                  "Item in list of categories of type {} instead of Category".format(type(category)))

        self.assertCountEqual([cat.getName() for cat in newsItem.getCategories()],
                              {"Startseite", "Forschung (keine Veranstaltungen)", "News / Pressemitteilungen",
                               "Deutsche Neuigkeiten"},
                              "Categories incorrectly parsed")

        # link
        self.assertEqual(newsItem.getLink(), "", "Link incorrectly parsed")

        # image
        self.assertEqual(newsItem.getImageLink(),
                         "https://www.uni-saarland.de/fileadmin/upload/_processed_/7/4/csm_Lautenschlaeger_Franziska_1ac5d22347.jpg",
                         "Image link incorrectly parsed")
        self.assertEqual("", newsItemNoImage.getImageLink(), "Missing image link incorrectly parsed")

    def test_eventDetails(self):
        """
        Tests if the details of a news item are correctly read
        """
        eventsList = self.parser.parseEvents(self.eventsfeed, 'de')

        eventItemNoContent = eventsList[0]
        eventItemWithContent = eventsList[1]

        # type
        self.assertIsInstance(eventItemNoContent, EventModel, "Event not of type EventModel")
        for event in eventsList:
            self.assertIsInstance(event, EventModel, "Event not of type EventModel")

        # title
        self.assertEqual("Tag der offenen Tür der Universität des Saarlandes", eventItemNoContent.getTitle(),
                         "Title incorrectly parsed")

        # published date (we expect the day to be the same)
        publishedDate = eventItemNoContent.getPublishedDate()
        now = datetime.now()
        self.assertEqual((now.year, now.month, now.day), (publishedDate.year, publishedDate.month, publishedDate.day),
                         "Published date incorrectly parsed")

        # happening date
        self.assertEqual(dateParser.parse("Sat, 16 May 2020 10:00:00 +0200").date(), eventItemNoContent.getHappeningDate(),
                         "Happening date incorrectly parsed")

        # description
        self.assertEqual("Am Samstag, den 16. Mai 2020, öffnet die Universität "
                          "des Saarlandes wieder ihre Türen. Über 200 Angebote aus "
                          "allen Fachrichtungen werden Forscherinnen und Forscher "
                          "sowie die Uni-Mitarbeiter und Studenten hierfür "
                          "zusammenstellen. Rund 10.000 Besucher kamen im Mai 2019 "
                          "zum Tag der offenen Tür auf den Saarbrücker Campus und "
                          "nutzten den Info-Tag zur Studienorientierung und um "
                          "einen Einblick in die Welt der Wissenschaft "
                          "zu bekommen.",
                         eventItemNoContent.getDescription(),
                         "Description incorrectly parsed")

        # content
        self.assertEqual("", eventItemNoContent.getContent(), "Empty Content incorrectly parsed")
        self.assertEqual(self.EVENT_ITEM_1_CONTENT.strip(), eventItemWithContent.getContent(), "Content incorrectly parsed")

        # categories
        self.assertIsInstance(eventItemNoContent.getCategories(), list,
                              "getCategories returns type {} instead of list".format(
                                  type(eventItemNoContent.getCategories())))
        # there is always a language category
        self.assertEqual(2, len(eventItemNoContent.getCategories()),
                         "Expected 2 categories, got {}".format(len(eventItemNoContent.getCategories())))

        for category in eventItemNoContent.getCategories():
            self.assertIsInstance(category, Category,
                                  "Item in list of categories of type {} instead of Category".format(type(category)))

        self.assertCountEqual([cat.getName() for cat in eventItemNoContent.getCategories()],
                              {"Veranstaltungen", "Deutsche Veranstaltungen"}, "Categories incorrectly parsed")

        # link
        self.assertEqual(eventItemNoContent.getLink(), "", "Link incorrectly parsed")

        # image
        self.assertEqual(eventItemNoContent.getImageLink(), "", "Missing image link incorrectly parsed")

    def test_exampleNewsFeed(self):
        """
        Test news parser on a miniature newsfeed containing only one item.
        This item has only only one category, this one is assigned twice, however.
        """

        newsList = self.parser.parseNews(self.exampleNewsfeed, 'de')

        # type
        self.assertIsInstance(newsList, list, "Expected newsList of type list, got {}".format(type(newsList)))

        # number of news items
        self.assertEqual(1, len(newsList), "Expected 1 news item, got {}".format(len(newsList)))

        newsItem = newsList[0]

        # type
        self.assertIsInstance(newsItem, NewsModel, "NewsItem of type {} instead of NewsModel".format(type(newsItem)))

        # title
        self.assertEqual("Title", newsItem.getTitle(), "Expected title 'Title', got {}".format(newsItem.getTitle()))

        # published date
        self.assertEqual(dateParser.parse("Thu, 02 Jan 2020 14:18:58 +0100").date(), newsItem.getPublishedDate(),
                         "Published date incorrectly parsed")

        # link
        self.assertEqual("Link", newsItem.getLink(), "Expected link 'Link', got {}".format(newsItem.getLink()))

        # description
        self.assertEqual("Description", newsItem.getDescription(),
                         "Expected description 'Description', got {}".format(newsItem.getDescription()))

        # content
        self.assertEqual("Content", newsItem.getContent(),
                         "Expected content 'Content', got {}".format(newsItem.getContent()))

        # image link
        self.assertEqual("imagelink", newsItem.getImageLink(),
                         "Expected image link 'imageLink', got {}".format(newsItem.getImageLink()))

        # categories
        self.assertIsInstance(newsItem.getCategories(), list,
                              "getCategories returns type {} instead of list".format(type(newsItem.getCategories())))
        self.assertEqual(len(newsItem.getCategories()), 2,
                         "Expected 2 categories, got {}".format(len(newsItem.getCategories())))

        category = newsItem.getCategories()[1]
        self.assertIsInstance(category, Category,
                              "Item in list of categories of type {} instead of Category".format(type(category)))

        # allCategories
        allCategories = self.parser.getCategories()
        self.assertEqual(7, len(allCategories), "Expected 7 categories, got {}".format(len(allCategories)))

    def test_exampleEventsfeed(self):
        """
        Test news parser on a miniature newsfeed containing only one item.
        """

        eventList = self.parser.parseEvents(self.exampleEventfeed, 'de')

        # type
        self.assertIsInstance(eventList, list, "Expected eventList of type list, got {}".format(type(eventList)))

        # number of news items
        self.assertEqual(1, len(eventList), "Expected 1 news item, got {}".format(len(eventList)))

        event = eventList[0]

        # type
        self.assertIsInstance(event, EventModel, "Event of type {} instead of EventModel".format(type(event)))

        # title
        self.assertEqual("Title", event.getTitle(), "Expected title 'Title', got {}".format(event.getTitle()))

        # happening date
        self.assertEqual(dateParser.parse("Sat, 16 May 2020 10:00:00 +0200").date(), event.getHappeningDate(),
                         "Happening date incorrectly parsed")

        # published date
        now = datetime.now()
        publishedDate = event.getPublishedDate()
        self.assertEqual((now.year, now.month, now.day), (publishedDate.year, publishedDate.month, publishedDate.day),
                         "Published date incorrectly parsed")

        # link
        self.assertEqual("Link", event.getLink(), "Expected link 'Link', got {}".format(event.getLink()))

        # description
        self.assertEqual("Description", event.getDescription(),
                         "Expected description 'Description', got {}".format(event.getDescription()))

        # content
        self.assertEqual("Content", event.getContent(),
                         "Expected content 'Content', got {}".format(event.getContent()))

        # image link
        self.assertEqual("imagelink", event.getImageLink(),
                         "Expected image link 'imageLink', got {}".format(event.getImageLink()))

        # categories
        self.assertIsInstance(event.getCategories(), list,
                              "getCategories returns type {} instead of list".format(type(event.getCategories())))
        self.assertEqual(len(event.getCategories()), 3,
                         "Expected 3 category, got {}".format(len(event.getCategories())))

        for category in event.getCategories():
            self.assertIsInstance(category, Category,
                                  "Item in list of categories of type {} instead of Category".format(type(category)))

        self.assertCountEqual([cat.getName() for cat in event.getCategories()],
                              {"Veranstaltungen", "Category1", "Deutsche Veranstaltungen"},
                              "Categories incorrectly parsed")

        # allCategories
        allCategories = self.parser.getCategories()
        self.assertEqual(8, len(allCategories), "Expected 8 categories, got {}".format(len(allCategories)))

    def test_emptyNewsfeed(self):
        """
        Test news parser on an empty newsfeed containing only one item.
        """

        newsList = self.parser.parseNews(self.emptyNewsfeed, 'de')
        allCategories = self.parser.getCategories()

        self.assertIsInstance(newsList, list, "newsList of type {}, expected list".format(type(newsList)))
        self.assertEqual(len(newsList), 0, "newsList has length {}, expected 0".format(len(newsList)))
        # the language categories (for news and events each) are always present
        self.assertEqual(6, len(allCategories), "Expected 6 categories, got {}".format(len(allCategories)))

    def test_emptyEventfeed(self):
        """
        Test events parser on an empty eventfeed containing only one item.
        """

        eventList = self.parser.parseEvents(self.emptyEventfeed, 'de')
        allCategories = self.parser.getCategories()
        eventCategories = self.parser.getEventCategories()

        self.assertIsInstance(eventList, list, "eventList of type {}, expected list".format(type(eventList)))
        self.assertEqual(len(eventList), 0, "eventList has length {}, expected 0".format(len(eventList)))
        # the language categories are always present
        self.assertEqual(6, len(allCategories), "Expected 6 categories, got {}".format(len(allCategories)))
        self.assertEqual(3, len(eventCategories), "Expected 3 categories, got {}".format(len(allCategories)))

    def test_oneCategoryTwoNewsItems(self):
        """
        Tests category parsing on a newsfeed with two elements of the same category
        """

        newsList = self.parser.parseNews(self.categoryNewsfeed, 'de')

        self.assertIsInstance(newsList, list, "newsList of type {}, expected list".format(type(newsList)))
        self.assertEqual(len(newsList), 2, "newsList has length {}, expected 2".format(len(newsList)))

        newsItem1 = newsList[0]
        newsItem2 = newsList[1]

        categories1 = newsItem1.getCategories()
        categories2 = newsItem2.getCategories()

        # type
        self.assertIsInstance(categories1, list, "getCategories returns {}, expected list".format(type(categories1)))
        self.assertIsInstance(categories2, list, "getCategories returns {}, expected list".format(type(categories2)))

        # number of categories per item
        self.assertEqual(len(categories1), 2, "Expected 2 categories, got {}".format(len(categories1)))
        self.assertEqual(len(categories2), 2, "Expected 2 categories, got {}".format(len(categories2)))

        category1 = categories1[1]
        category2 = categories2[1]

        # type of category
        self.assertIsInstance(category1, Category, "Category of type {} instead of Category".format(type(category1)))
        self.assertIsInstance(category2, Category, "Category of type {} instead of Category".format(type(category2)))

        # all categories
        allCategories = self.parser.getCategories()

        self.assertEqual(7, len(allCategories), "Expected 7 category, got {}".format(len(allCategories)))

    def test_categoryNewsAndEvent(self):
        """
        Tests the assignment of category IDs. In this test a newsfeed and eventfeed get parsed, both with an item that
        share a category.
        """

        eventList = self.parser.parseEvents(self.exampleEventfeed, 'de')
        newsList = self.parser.parseNews(self.exampleNewsfeed, 'de')
        allCategories = self.parser.getCategories()

        self.assertEqual(8, len(allCategories), "Expected 8 categories, got {}".format(len(allCategories)))
        categoryList = [Category(name, len(name)) for name in ["Veranstaltungen", "Category1",
                                                                         "Deutsche Veranstaltungen", "Deutsche Neuigkeiten", "English News", "English Events",
                                                                         "Actualités Françaises", "Événements Français"]]
        self.assertCountEqual([cat.getName() for cat in allCategories], ["Veranstaltungen", "Category1",
                                                                         "Deutsche Veranstaltungen", "Deutsche Neuigkeiten", "English News", "English Events",
                                                                         "Actualités Françaises", "Événements Français"],
                              "Parsed categories incorrectly.")

        for cat in allCategories:
            self.assertGreater(8, cat.getID(), "ID should be less than 8, got {}".format(cat.getID()))
            if cat.getName() == "Category1":
                id1 = cat.getID()

        event = eventList[0]
        for cat in event.getCategories():
            if cat.getName() == "Category1":
                eventCategory1 = cat

        newsItem = newsList[0]
        for cat in newsItem.getCategories():
            if cat.getName() == "Category1":
                newsCategory1 = cat

        self.assertEqual(id1, eventCategory1.getID(), "ID of Category1 does not match")
        self.assertEqual(id1, newsCategory1.getID(), "ID of Category1 does not match")

if __name__ == '__main__':
    unittest.main()

