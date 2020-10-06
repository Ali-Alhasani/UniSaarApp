import http.server
import json
from urllib.parse import urlparse, parse_qs
from datetime import datetime
from dateutil import parser as dateParser
from source.parsers.DirectoryParser import UnspecificSearchQueryException


class PathError(Exception):
    pass


class WebViewError(Exception):
    pass


class RequestHandler(http.server.BaseHTTPRequestHandler):

    def splitURLPath(self, path):
        """
        returns a list of path segments. Segments should use delimiter '/' and start with '/'
        @param path: string, for example '/path/to/something'
        @return: list, [ 'path', 'to', 'something' ]
        """
        splitPath = path.split('/')
        if not splitPath[0] == '':
            raise PathError
        if splitPath[-1] == '':
            return splitPath[1:-1]
        else:
            return splitPath[1:]

    def do_GET(self):
        """
        Handles a get request to the Server.
        """
        # parse the url
        u = urlparse(self.path)
        q = parse_qs(u.query)
        try:
            p = self.splitURLPath(u.path)
        except PathError:
            self.error400()
            return
        pathLength = len(p)

        # call the correct methods for the request
        try:
            if pathLength == 0:
                raise PathError

            if p[0] == 'news':
                if pathLength < 2:
                    raise PathError

                if p[1] == 'mainScreen':
                    page = int(q['page'][0])
                    pageSize = int(q['pageSize'][0])
                    if 'language' in q.keys():
                        language = q['language'][0]
                    else:
                        language = None
                    filterIDs = None
                    negFilterIDs = None
                    if 'filter' in q:
                        filterIDs = []
                        for s in q['filter']:
                            l = s.split(',')
                            for i in l:
                                filterIDs.append(int(i))
                    if 'negFilter' in q:
                        negFilterIDs = []
                        for s in q['negFilter']:
                            l = s.split(',')
                            for i in l:
                                negFilterIDs.append(int(i))
                    self.getNewsFeedMainScreen(page, pageSize, language, filterIDs, negFilterIDs)
                elif p[1] == 'details':
                    id = int(q['id'][0])
                    language = q['language'][0] if 'language' in q.keys() else 'en'
                    try:
                        self.getNewsFeedNewsDetails(id, language)
                    except Exception as e:
                        raise WebViewError
                elif p[1] == 'categories':
                    if 'language' in q.keys():
                        language = q['language'][0]
                    else:
                        language = None
                    self.getNewsFeedCategories(language)
                else:
                    raise PathError
            elif p[0] == 'events':
                if pathLength < 2:
                    raise PathError

                if p[1] == 'mainScreen':
                    year = int(q['year'][0])
                    month = int(q['month'][0])
                    if 'language' in q.keys():
                        language = q['language'][0]
                    else:
                        language = None
                    filterIDs = None
                    negFilterIDs = None
                    if 'filter' in q:
                        filterIDs = []
                        for s in q['filter']:
                            l = s.split(',')
                            for i in l:
                                filterIDs.append(int(i))
                    if 'negFilter' in q:
                        negFilterIDs = []
                        for s in q['negFilter']:
                            l = s.split(',')
                            for i in l:
                                negFilterIDs.append(int(i))
                    self.getNewsFeedEvents(year, month, language, filterIDs, negFilterIDs)
                elif p[1] == "categories":
                    if 'language' in q.keys():
                        language = q['language'][0]
                    else:
                        language = None
                    self.getNewsFeedEventCategories(language)
                elif p[1] == 'details':
                    id = int(q['id'][0])
                    language = q['language'][0] if 'language' in q.keys() else 'en'
                    try:
                        self.getNewsFeedEventDetails(id, language)
                    except Exception as e:
                        raise WebViewError
                elif p[1] == 'iCal':
                    id = int(q['id'][0])
                    try:
                        self.getNewsFeedEventICal(id)
                    except Exception as e:
                        raise WebViewError
                else:
                    raise PathError
            elif p[0] == 'mensa':
                if pathLength < 2:
                    raise PathError

                if p[1] == 'filters':
                    language = q['language'][0]
                    self.getMensaFilters(language=language)
                elif p[1] == 'info':
                    locationID = q['location'][0]
                    language = q['language'][0]
                    self.getMensaInfo(locationID=locationID, language=language)
                elif p[1] == 'mainScreen':
                    locationID = q['location'][0]
                    language = q['language'][0]
                    date = dateParser.parse(q['date'][0]) if 'date' in q.keys() else None
                    self.getMensaMainScreen(locationID=locationID, language=language, date=date)
                elif p[1] == 'mealDetail':
                    mealID = int(q['meal'][0])
                    language = q['language'][0]
                    self.getMensaDetailScreen(mealID=mealID, language=language)
                else:
                    raise PathError
            elif p[0] == 'directory':
                if pathLength < 2:
                    raise PathError

                if p[1] == 'search':
                    page = int(q['page'][0])
                    pageSize = int(q['pageSize'][0])
                    searchQuery = q['query'][0]
                    if 'language' in q.keys():
                        lang = q['language'][0]
                    else:
                        lang = 'de'
                    self.searchDirectory(searchQuery=searchQuery, page=page, pageSize=pageSize, lang=lang)
                elif p[1] == 'personDetails':
                    pID = int(q['pid'][0])
                    language = q['language'][0]
                    self.showDirectoryPerson(pID=pID, language=language)
                elif p[1] == 'image':
                    name = q['name'][0]
                    self.showImage(name=name)
                elif p[1] == 'helpfulNumbers':
                    language = q['language'][0]
                    if 'lastUpdated' in q.keys():
                        lastUpdatedValue = q['lastUpdated'][0]
                        if not lastUpdatedValue == 'never':
                            lastUpdated = dateParser.parse(lastUpdatedValue)
                        else:
                            lastUpdated = None
                    else:
                        lastUpdated = None
                    self.showHelpfulNumbers(language=language, lastUpdated=lastUpdated)
                else:
                    raise PathError
            elif p[0] == 'map':
                if 'lastUpdated' in q.keys():
                    lastUpdateTime = dateParser.parse(q['lastUpdated'][0])
                    self.getMap(lastUpdateTime)
                else:
                    self.getMap()
            elif p[0] == 'more':
                # /more?language=something&lastUpdated=timestamp
                language = q['language'][0]
                if 'lastUpdated' in q.keys():
                    lastUpdatedValue = q['lastUpdated'][0]
                    if not lastUpdatedValue == 'never':
                        lastUpdated = dateParser.parse(lastUpdatedValue)
                    else:
                        lastUpdated = None
                else:
                    lastUpdated = None
                self.getMore(language, lastUpdated)
            else:
                raise PathError
        # Any exception that is thrown at lower levels with a specific error attributed to it
        # should be caught here in its own except block. For these cases, individual error messages
        # may be sent
        except (PathError, KeyError) as e:
            # client error, invalid path or missing parameter
            self.error400()
        except WebViewError as e:
            # show error webpage
            self.errorWebview()
        except UnspecificSearchQueryException as e:
            # show an error that the search query was not specific enough
            self.errorUnspecificSearchQuery(e.language)
        except Exception as e:
            # server error
            self.error500()

    def getMensaMainScreen(self, locationID, language, date):
        responseJSON = self.server.requestMensaMainScreen(locationID=locationID, language=language, date=date)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getMensaDetailScreen(self, mealID, language):
        responseJSON = self.server.requestMensaDetailScreen(mealID=mealID, language=language)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getMensaInfo(self, locationID, language):
        responseJSON = self.server.requestMensaInfo(locationID=locationID, language=language)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getMensaFilters(self, language):
        responseJSON = self.server.requestMensaFilters(language=language)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getNewsFeedMainScreen(self, page, pageSize, language, filterIDs=None, negFilterIDs=None):
        responseJSON = self.server.requestNewsFeedMainScreen(page, pageSize, language, filterIDs, negFilterIDs)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getNewsFeedNewsDetails(self, newsID, language):
        responseHTML = self.server.requestNewsDetails(newsID, language)

        self.send_response(code=200)
        self.send_header('content-type', 'text/html; charset=utf-8')
        self.end_headers()

        self.wfile.write(responseHTML.encode())

    def getNewsFeedEventDetails(self, eventID, language):
        responseHTML = self.server.requestEventDetails(eventID, language)

        self.send_response(code=200)
        self.send_header('content-type', 'text/html; charset=utf-8')
        self.end_headers()

        self.wfile.write(responseHTML.encode())

    def getNewsFeedEventICal(self, eventID):
        responseICS = self.server.requestEventICal(eventID)

        self.send_response(code=200)
        self.send_header('content-type', 'text/calendar')
        self.end_headers()

        self.wfile.write(responseICS)

    def getNewsFeedEvents(self, year, month, language=None, filterIDs=None, negFilterIDs=None):
        responseJSON = self.server.requestEvents(year, month, language, filterIDs, negFilterIDs)
        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()
        self.wfile.write(responseJSON.encode())

    def getNewsFeedEventCategories(self, language):
        responseJSON = self.server.requestEventCategories(language)
        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()
        self.wfile.write(responseJSON.encode())

    def getNewsFeedCategories(self, language):
        responseJSON = self.server.requestNewsFeedCategories(language)
        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()
        self.wfile.write(responseJSON.encode())

    def getMore(self, lang, time):
        responseJSON = self.server.requestMore(lang, time)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def searchDirectory(self, searchQuery: str, page: int, pageSize: int, lang):
        responseJSON = self.server.searchDirectory(searchQuery=searchQuery, page=page, pageSize=pageSize, lang=lang)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def showDirectoryPerson(self, pID: int, language: str):
        responseJSON = self.server.requestPersonDetails(pID=pID, language=language)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def showImage(self, name: str):
        responseImage = self.server.showImage(name=name)

        self.send_response(code=200)
        self.send_header('content-type', 'image/jpeg')
        self.end_headers()

        self.wfile.write(responseImage)

    def showHelpfulNumbers(self, language: str, lastUpdated: datetime):
        responseJSON = self.server.showHelpfulNumbers(language=language, lastUpdated=lastUpdated)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def getMap(self, lastUpdateTime=None):
        responseJSON = self.server.requestMap(lastUpdateTime)

        self.send_response(code=200)
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def error400(self):
        responseJSON = json.dumps("This request is invalid.")

        self.send_response(code=400)
        self.send_header('Connection', 'close')
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def error500(self):
        responseJSON = json.dumps("A server error occurred")

        self.send_response(code=500)
        self.send_header('Connection', 'close')
        self.send_header('content-type', 'application/json')
        self.end_headers()

        self.wfile.write(responseJSON.encode())

    def errorWebview(self, language='en'):
        responseHTML = self.server.requestErrorPage(language)

        self.send_response(code=400)
        self.send_header('Connection', 'close')
        self.send_header('content-type', 'text/html; charset=utf-8')
        self.end_headers()

        self.wfile.write(responseHTML.encode())

    def errorUnspecificSearchQuery(self, language='en'):
        if language == 'fr':
            responseJSON = json.dumps("Il y avait trop r&eacute;sultats avec cette demande. Pri&egrave;re d' essayer encore une fois avec une demande plus specifique.")
        elif language == 'de':
            responseJSON = json.dumps("F&uuml;r diese Suchanfrage gab es zu viele Ergebnisse. Bitte versuch es noch einmal mit einer genaueren Anfrage.")
        else:
            responseJSON = json.dumps("There were too many results for this query. Please try again with a more precise query.")


        self.send_response(code=400)
        self.send_header('Connection', 'close')
        self.send_header('content-type', 'text/html; charset=utf-8')
        self.end_headers()

        self.wfile.write(responseJSON.encode())
