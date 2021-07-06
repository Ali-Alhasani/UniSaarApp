import unittest
from source.networking.UniAppServer import UniAppServer
from source.networking.NetworkManager import NetworkManager
from source.parsers.MensaParser import MensaParser
from datetime import datetime
from source.views.MensaView import MensaView
from source.networking.RequestHandler import RequestHandler
from source.models.MensaModel import MensaModel
import json


class ServerIntegrationTest(unittest.TestCase):
    def setUp(self) -> None:
        networkManager = NetworkManager()
        self.server = UniAppServer(('localhost', 3000), RequestHandler, networkManager)
        self.maxDiff = None

    def tearDown(self) -> None:
        self.server.server_close()

    def test_mensaMenuMainScreenSB(self):
        self.server.updateMensa()
        self.assertTrue(self.server.mensaController.mensaModel.isUpToDate())
        self.server.requestMensaMainScreen('sb', 'de', datetime.today())

    def test_mensaMenuMainScreenHOM(self):
        self.server.updateMensa()
        self.server.requestMensaMainScreen('hom', 'de', datetime.today())

    def test_mensaMenuMainScreenMusik(self):
        self.server.updateMensa()
        self.server.requestMensaMainScreen('musiksb', 'de', datetime.today())

    def test_mensaMenuFilters(self):
        self.server.updateMensa()
        self.server.requestMensaFilters('de')

    def test_mensaMenuInfo(self):
        self.server.updateMensa()
        self.server.requestMensaInfo('sb', 'de')

    def test_mensaMenuDetails(self):
        self.server.updateMensa()
        self.server.requestMensaDetailScreen(0, 'de')

    def test_mensaMenuDetailsNonexistentMeal(self):
        try:
            self.server.updateMensa()
            self.server.requestMensaDetailScreen(100000000, 'de')
            self.assertTrue(False, "should have thrown an exception")
        except Exception:
            self.assertTrue(True)

    def test_mensaMenuMainScreenNonexistentLocation(self):
        try:
            self.server.updateMensa()
            self.server.requestMensaMainScreen('uiae', 'de', datetime.today())
            self.assertTrue(False, "should have thrown an exception")
        except Exception:
            self.assertTrue(True)

    def test_mensaMenuMainScreenWrongLanguage(self):
        try:
            self.server.updateMensa()
            self.server.requestMensaMainScreen('sb', 'uitdare', datetime.today())
            self.assertTrue(False, "should have thrown an exception")
        except Exception:
            self.assertTrue(True)

    def test_newsMainScreen(self):
        self.server.updateNewsFeed()
        self.server.requestNewsFeedMainScreen(0, 10, 'de')

    def test_newsMainScreenFilter(self):
        self.server.updateNewsFeed()
        filters = [0, 1, 100]
        newsJSON = self.server.requestNewsFeedMainScreen(0, 100, 'de', filters)
        newsDict = json.loads(newsJSON)
        for news in newsDict['items']:
            cats = news['categories']
            catKeys = [int(x) for x in cats.keys()]
            checkBool = False
            for catID in catKeys:
                if catID in filters:
                    checkBool = True
            self.assertTrue(checkBool)

    def test_newsMainScreenNegFilter(self):
        self.server.updateNewsFeed()
        negFilters = [1, 2, 3]
        newsJSON = self.server.requestNewsFeedMainScreen(0, 1000, 'de', None, negFilters)
        newsDict = json.loads(newsJSON)
        for news in newsDict['items']:
            cats = news['categories']
            catKeys = [int(x) for x in cats.keys()]
            self.assertFalse(set(catKeys) <= set(negFilters))

    def test_newsMainScreenBothFilters(self):
        self.server.updateNewsFeed()
        filters = [4, 2, 5]
        negFilters = [1, 2, 3]
        newsJSON = self.server.requestNewsFeedMainScreen(0, 1000, 'de', filters, negFilters)
        newsDict = json.loads(newsJSON)
        for news in newsDict['items']:
            cats = news['categories']
            catKeys = [int(x) for x in cats.keys()]
            checkBool = False
            for catID in catKeys:
                if catID in filters:
                    checkBool = True
            self.assertTrue(checkBool)
            self.assertFalse(set(catKeys) <= set(negFilters))

    def test_newsMainScreenPageTooLarge(self):
        try:
            self.server.updateNewsFeed()
            self.server.requestNewsFeedMainScreen(1000, 1000, 'de')
            self.assertTrue(False, "should have thrown an exception")
        except Exception:
            self.assertTrue(True)

    def test_newsDetailsExistent(self):
        self.server.updateNewsFeed()
        self.server.requestNewsDetails(899, 'de')

    def test_newsDetailsNonexistent(self):
        try:
            self.server.updateNewsFeed()
            self.server.requestNewsDetails(100000000, 'de')
            self.assertTrue(False, "should have thrown an exception")
        except Exception:
            self.assertTrue(True)

    def test_newsCategories(self):
        self.server.requestNewsFeedCategories('de')

    def test_eventCategories(self):
        self.server.requestEventCategories('de')

    def test_eventsMainScreen(self):
        self.server.updateNewsFeed()
        self.server.requestEvents(2020, 2, 'de')

    def test_eventsMainScreenFilter(self):
        self.server.updateNewsFeed()
        filters = [0, 1, 10, 12, 1000]
        eventsJSON = self.server.requestEvents(2020, 2, 'de', filters, None)
        eventsDict = json.loads(eventsJSON)
        for event in eventsDict['items']:
            cats = event['categories']
            catKeys = [int(x) for x in cats.keys()]
            checkBool = False
            for catID in catKeys:
                if catID in filters:
                    checkBool = True
            self.assertTrue(checkBool)

    def test_eventsMainScreenNegFilter(self):
        self.server.updateNewsFeed()
        negFilters = [0, 1, 10, 12, 1000]
        eventsJSON = self.server.requestEvents(2020, 2, 'de', None, negFilters)
        eventsDict = json.loads(eventsJSON)
        for event in eventsDict['items']:
            cats = event['categories']
            catKeys = [int(x) for x in cats.keys()]
            self.assertFalse(set(catKeys) <= set(negFilters))

    def test_eventsMainScreenBothFilters(self):
        self.server.updateNewsFeed()
        filters = [0, 1, 10, 12, 1000]
        negFilters = [0, 4, 5]
        eventsJSON = self.server.requestEvents(2020, 2, 'de', filters, negFilters)
        eventsDict = json.loads(eventsJSON)
        for event in eventsDict['items']:
            cats = event['categories']
            catKeys = [int(x) for x in cats.keys()]
            checkBool = False
            for catID in catKeys:
                if catID in filters:
                    checkBool = True
            self.assertTrue(checkBool)
            self.assertFalse(set(catKeys) <= set(negFilters))

    def test_eventsDetailsExistent(self):
        self.server.updateNewsFeed()
        self.server.requestEventDetails(951, 'de')

    def test_eventsDetailsNonExistent(self):
        try:
            self.server.updateNewsFeed()
            self.server.requestEventDetails(12121212121212, 'de')
        except:
            self.assertTrue(True)

    def test_eventsICalExistent(self):
        self.server.updateNewsFeed()
        self.server.requestEventICal(951)

    def test_eventsICalNonExistent(self):
        try:
            self.server.updateNewsFeed()
            self.server.requestEventICal(12121212121212)
        except:
            self.assertTrue(True)

    def test_directorySearch(self):
        searchResult = self.server.searchDirectory('Zeller', 0, 10, 'de')
        searchResultDict = json.loads(searchResult)
        self.assertEqual(4, searchResultDict['itemCount'])
        person = json.loads(self.server.requestPersonDetails(searchResultDict['results'][1]['pid'], 'de'))
        self.assertEqual('Andreas', person['firstname'])

    def test_directorySearchCache(self):
        self.server.searchDirectory('Zeller', 0, 10, 'de')
        searchResult = self.server.searchDirectory('Zeller', 0, 10, 'de')
        searchResultDict = json.loads(searchResult)
        self.assertEqual(4, searchResultDict['itemCount'])
        person = json.loads(self.server.requestPersonDetails(searchResultDict['results'][1]['pid'], 'de'))
        self.assertEqual('Andreas', person['firstname'])


    def test_directoryHelpfulNumbersNotUpToDate(self):
        self.server.updateHelpfulNumbers()
        self.server.showHelpfulNumbers('de', None)

    def test_directoryHelpfulNumbersUpToDate(self):
        self.server.updateHelpfulNumbers()
        self.assertTrue(self.server.showHelpfulNumbers('de', datetime(2021, 12, 12)).__contains__('still up to date'))

    def test_moreUpToDate(self):
        self.server.requestMore('de', datetime.now())

    def test_moreNotUpToDate(self):
        self.server.requestMore('de', None)

    def test_mapNotUpToDate(self):
        self.server.updateMap()
        self.server.requestMap(None)

    def test_mapUpToDate(self):
        self.server.updateMap()
        self.server.requestMap(datetime.now())


if __name__ == '__main__':
    unittest.main()
