import unittest
from source.networking.UniAppServer import UniAppServer
from source.networking.RequestHandler import RequestHandler
from source.networking.NetworkManager import NetworkManager
import threading
import socket
from io import BytesIO as IO

HOST = 'localhost'
PORT = 3000


class TestableHandler(RequestHandler):
    # On Python3, in socketserver.StreamRequestHandler, if this is
    # set it will use makefile() to produce the output stream. Otherwise,
    # it will use socketserver._SocketWriter, and we won't be able to get
    # to the data
    wbufsize = 1

    def finish(self):
        # Do not close self.wfile, so we can read its value
        self.wfile.flush()
        self.rfile.close()

    def date_time_string(self, timestamp=None):
        """ Mocked date time string """
        return 'DATETIME'

    def version_string(self):
        """ mock the server id """
        return 'BaseHTTP/x.x Python/x.x.x'


class MockSocket(object):
    def getsockname(self):
        return ('sockname',)


class MockRequest(object):
    _sock = MockSocket()

    def __init__(self, path):
        self._path = path

    def makefile(self, *args, **kwargs):
        if args[0] == 'rb':
            return IO(b"GET %s HTTP/1.0" % self._path)
        elif args[0] == 'wb':
            return IO(b'')
        else:
            raise ValueError("Unknown file type to make", args, kwargs)


class RequestHandlerUnitTest(unittest.TestCase):
    def _test(self, request, server):
        handler = TestableHandler(request, (0, 0), server)
        return handler.wfile.getvalue()

    def test_requestNewsMainScreen(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/news/mainScreen?page=0&pageSize=10&filter=1,2,3&negFilter=4'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('itemCount' in str(res))
        self.assertTrue('items' in str(res))

    def test_requestNewsDetails(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/news/details?id=951'), server)
        self.assertTrue('text/html' in str(res))

    def test_requestNewsCategories(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/news/categories'), server)
        self.assertTrue('application/json' in str(res))

    def test_requestEventsMainScreen(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/events/mainScreen?year=2020&month=03&filter=0,1,2,3,4,5,6,7,8,13&negFilter=20'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('items' in str(res))
        self.assertTrue('Semestertermine' in str(res))
        self.assertTrue('Veranstaltungen' in str(res))

    def test_requestEventsDetails(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/events/details?id=901'), server)
        self.assertTrue('text/html' in str(res))

    def test_requestEventsCategories(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/events/categories'), server)
        self.assertTrue('application/json' in str(res))

    def test_requestEventsIcal(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/events/iCal?id=901'), server)
        self.assertTrue('text/calendar' in str(res))
        self.assertTrue('BEGIN:VCALENDAR' in str(res))

    def test_requestMensaHom(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMensa()
        res = self._test(MockRequest(b'/mensa/mainScreen?location=hom&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('Komplettmen' in str(res))

    def test_requestMensaSB(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMensa()
        res = self._test(MockRequest(b'/mensa/mainScreen?location=sb&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('Komplettmen' in str(res))

    def test_requestMensaDetails(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMensa()
        res = self._test(MockRequest(b'/mensa/mealDetail?meal=0&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('Hackst' in str(res))

    def test_requestMensaFilters(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMensa()
        res = self._test(MockRequest(b'/mensa/filters?language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('locations' in str(res))
        self.assertTrue('notices' in str(res))

    def test_requestMensaInfo(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMensa()
        res = self._test(MockRequest(b'/mensa/info?location=sb&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('name' in str(res))
        self.assertTrue('description' in str(res))

    def test_requestDirectorySearch(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        res = self._test(MockRequest(b'/directory/search?page=0&pageSize=10&query=zeller'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('name' in str(res))
        self.assertTrue('Zeller' in str(res))

    def test_requestDirectoryPersonDetails(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        res = self._test(MockRequest(b'/directory/personDetails?pid=-1&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('firstname' in str(res))
        self.assertTrue('gender' in str(res))

    def test_requestDirectoryHelpfulNumbers(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateHelpfulNumbers()
        res = self._test(MockRequest(b'/directory/helpfulNumbers?language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('numbersLastChanged' in str(res))
        self.assertTrue('numbers' in str(res))

    def test_requestMap(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMap()
        res = self._test(MockRequest(b'/map?lastUpdated=2019-01-20'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('campus' in str(res))
        self.assertTrue('latitude' in str(res))

    def test_requestMore(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateMap()
        res = self._test(MockRequest(b'/more?lastUpdated=2019-01-20&language=de'), server)
        self.assertTrue('application/json' in str(res))
        self.assertTrue('linksLastChanged' in str(res))
        self.assertTrue('language' in str(res))
        self.assertTrue('name' in str(res))

    def test_error400(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        res = self._test(MockRequest(b'/this/is/not/allowed'), server)
        self.assertTrue('This request is invalid.' in str(res))

    def test_error500(self):
        server = None
        res = self._test(MockRequest(b'/news/categories'), server)
        self.assertTrue('A server error occurred' in str(res))

    def test_webviewError(self):
        nm = NetworkManager()
        server = UniAppServer(('localhost', 0), TestableHandler, nm)
        server.updateNewsFeed()
        res = self._test(MockRequest(b'/news/details?id=40000'), server)
        self.assertTrue('text/html' in str(res))


if __name__ == '__main__':
    unittest.main()

