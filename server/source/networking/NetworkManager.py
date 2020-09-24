import requests
from bs4 import BeautifulSoup
from os import path
from source.Constants import ACADEMIC_CALENDAR_FOLDER


class NetworkManager:

    def __init__(self):
        """
        Create a new Network Manager. All fields containing static data such as target URL parts should be set here.
        """
        # Mensa: see mensa_API_doc.html
        # password assigned by F. Freiberger
        self._MENSA_SCHEME = 'https:'
        self._MENSA_AUTHORITY = '//mensaar.de'
        self._MENSA_BASE_PATH = '/api/1/pt5p8UGNiG2GzNGQxCQ8/1'

        # News and events: see https://www.uni-saarland.de/universitaet/aktuell/ => RSS feeds
        # the general queries are still missing a key-value pair 'L': l for the language
        # l = '0' should be German, l = '1' English, l = '2' French
        # at the moment there don't seem to be any non-German News or Events
        self._NEWS_SCHEME = 'https:'
        self._NEWS_AUTHORITY = '//www.uni-saarland.de'
        self._NEWS_BASE_PATH = '/universitaet/aktuell/news.html'
        self._NEWS_GENERAL_QUERY = {'type': '9818', 'cat': '47'}

        self._EVENTS_SCHEME = 'https:'
        self._EVENTS_AUTHORITY = '//www.uni-saarland.de'
        self._EVENTS_BASE_PATH = '/universitaet/aktuell/veranstaltungen.html'
        self._EVENTS_GENERAL_QUERY = {'type': '9818', 'cat': '50'}

        # Directory:
        # At the moment we parse HTML pages generated when using the lsf search functionality
        self._DIRECTORY_SCHEME = 'https:'
        self._DIRECTORY_AUTHORITY = '//www.lsf.uni-saarland.de'
        self._DIRECTORY_BASE_PATH = '/qisserver/rds'
        self._DIRECTORY_SEARCH_QUERY = {'state': 'wsearchv', 'search': '7', 'purge': 'y',
                                        'moduleParameter': 'person/person', '_form': 'display'}
        self._DIRECTORY_PERSON_QUERY = {'state': 'verpublish', 'status': 'init', 'vmfile': 'no',
                                        'moduleCall': 'webInfo', 'publishConfFile': 'webInfoPerson',
                                        'publishSubDir': 'personal', 'keep': 'y', 'purge': 'y'}

        # Academic Calendar
        self._AC_SCHEME = 'https:'
        self._AC_AUTHORITY = '//www.uni-saarland.de/'
        self._AC_LINK_PATH = 'studium/organisation/termine.html'

    def languageCodeToNewsCode(self, languageCode: str) -> str:
        """
        Maps a language code to a numerical code. Mapping:
            'de' -> '0'
            'en' -> '1'
            'fr' -> '2'
        This is used for requesting news/events in the corresponding language
        @param languageCode: string, language code
        @return: string
        """
        if languageCode == 'de':
            return '0'
        elif languageCode == 'en':
            return '1'
        elif languageCode == 'fr':
            return '2'
        else:
            raise ValueError

    def _fetchExternalData(self, scheme: str, authority: str, path: str, query: dict = None, byte: bool = False) -> tuple:
        """
        Creates a HTTP GET-request to the URL 'scheme://authority/path?query'. This should not be accessed from objects
        other than self. Instead the methods below should be used.
        @param scheme: string, a URL scheme (like 'https:'), has to end with ':'
        @param authority: string, URL authority, usually the host address, has to start with '//'
        @param path: string, URL path, has to start with '/'
        @param query: dict (optional), query arguments as key-value pairs
        @param byte: bool (optional), returns request content as binary
        @return: pair of the text returned by the request and the content type
        """
        if query is None:
            query = {}

        url = scheme + authority + path

        # create http request
        r = requests.get(url, params=query)

        if not r.status_code == requests.codes.ok:
            raise ConnectionError
        if byte:
            return r.content, r.headers.get('Content-Type')
        else:
            return r.text, r.headers.get('Content-Type')

    def fetchMensaMenu(self, location: str, language: str) -> str:
        """
        Fetches the mensa menu of a certain location from the Mensa API.
        @param location: string, location ID as specified by mensa base data
        @param language: string, language code
        @return: string of the location's menu
        """
        urlPath = self._MENSA_BASE_PATH + '/' + language + '/getMenu/' + location

        menu, _ = self._fetchExternalData(scheme=self._MENSA_SCHEME, authority=self._MENSA_AUTHORITY, path=urlPath)

        return menu

    def fetchMensaBaseData(self, language: str) -> str:
        """
        Fetches the mensa base data from the Mensa API
        @param language: string, language code
        @return: string of the mensa base data
        """
        urlPath = self._MENSA_BASE_PATH + '/' + language + '/getBaseData'

        baseData, _ = self._fetchExternalData(scheme=self._MENSA_SCHEME, authority=self._MENSA_AUTHORITY, path=urlPath)

        return baseData

    def fetchNews(self, language: str) -> str:
        """
        Fetches the news from the University News RSS feed
        @param language: string, language code
        @return: string of the news
        """
        urlQuery = self._NEWS_GENERAL_QUERY
        urlQuery['L'] = self.languageCodeToNewsCode(language)
        try:

            news, contentType = self._fetchExternalData(scheme=self._NEWS_SCHEME, authority=self._NEWS_AUTHORITY,
                                                        path=self._NEWS_BASE_PATH, query=urlQuery)
        except ConnectionError as e:
            # the news website shows a 404 error if no news in the selected language is available
            news = ''

        #if 'text/xml' not in contentType:
            # we expect to get a data of content-type text/xml in a successful request
            # this was probably only valid before the website for news changed, s.t. asking for
            # news in languages where there is none now returns a 404
            #raise ContentTypeError(contentType, 'text/xml')
        #    pass

        return news

    def fetchEvents(self, language: str) -> str:
        """
        Fetches the events from the University Events RSS feed
        @param language: string, language code
        @return: string of the events
        """
        urlQuery = self._EVENTS_GENERAL_QUERY
        urlQuery['L'] = self.languageCodeToNewsCode(language)

        try:
            events, contentType = self._fetchExternalData(scheme=self._EVENTS_SCHEME, authority=self._EVENTS_AUTHORITY,
                                                      path=self._EVENTS_BASE_PATH, query=urlQuery)
        except ConnectionError:
            events = ''

        #if 'text/xml' not in contentType:
            # we expect to get a data of content-type text/xml in a successful request
            # a problem with this is the request for a non-German rss feed which returns a webpage
            #raise ContentTypeError(contentType, 'text/html')
        #    pass

        return events

    def fetchDirectorySearchResults(self, firstname: str, lastname: str, page: int, pageSize: int):
        """
        Fetches search results for the query for firstname lastname from the lsf website. Supports paging
        @param firstname: str
        @param lastname: str
        @param page: int
        @param pageSize: int
        @return: str, HTML
        """
        urlQuery = self._DIRECTORY_SEARCH_QUERY.copy()
        # providing the parameter w/o a value does not yield the correct results
        if not firstname == '':
            urlQuery['personal.vorname'] = firstname
        if not lastname == '':
            urlQuery['personal.nachname'] = lastname
        urlQuery['P_start'] = str(page*pageSize)
        urlQuery['P_anzahl'] = str(pageSize)

        searchResultsHTML, _ = self._fetchExternalData(scheme=self._DIRECTORY_SCHEME,
                                                       authority=self._DIRECTORY_AUTHORITY,
                                                       path=self._DIRECTORY_BASE_PATH, query=urlQuery)

        return searchResultsHTML

    def fetchPersonDetails(self, pID: int):
        """
        Fetches person details for person with pID from the lsf website.
        @param pID: int
        @return: str, HTML
        """
        urlQuery = self._DIRECTORY_PERSON_QUERY
        urlQuery['personal.pid'] = str(pID)

        personDetailsHTML, _ = self._fetchExternalData(scheme=self._DIRECTORY_SCHEME,
                                                       authority=self._DIRECTORY_AUTHORITY,
                                                       path=self._DIRECTORY_BASE_PATH, query=urlQuery)

        return personDetailsHTML

    def getAcademicCalendarLinks(self, webpage: str) -> list:
        """
        Scrapes the a html returned from 'https://www.uni-saarland.de/studium/organisation/termine.html' for the links
        containing the pdfs with the academic calendar
        @param webpage: str, html
        @return: list of links (str)
        """
        soup = BeautifulSoup(webpage, features="html.parser")

        links = []
        for link in soup.find_all('a'):
            url = link.get('href')
            try:
                if url is not None and 'semester' in url.lower() and '.pdf' in url.lower():
                    links.append(url)
            except AttributeError:
                pass
        return links

    def getAcademicCalendarPDFFiles(self):
        """
        fetches the pdf files for the academic calendar that exist by using getAcademicCalendarLinks and
        writes them into the folder academic_calendar
        :return the names of the written files
        """
        academicCalendarWebsite, _ = self._fetchExternalData(self._AC_SCHEME, self._AC_AUTHORITY,
                                                                self._AC_LINK_PATH)
        folder = ACADEMIC_CALENDAR_FOLDER
        academicCalendarLinks = self.getAcademicCalendarLinks(academicCalendarWebsite)
        names = []
        for link in academicCalendarLinks:
            splitLink = link.split('/')
            name = splitLink[len(splitLink) - 1]
            names.append(folder + name)
            #if not path.exists(folder + name):
            pdf, _ = self._fetchExternalData(scheme=self._AC_SCHEME, authority=self._AC_AUTHORITY,
                                            path=link, byte=True)
            with open(folder + name, 'wb') as f:
                f.write(pdf)
        return names


class ContentTypeError (Exception):
    def __init__(self, contentType, expectedContentType):
        self.contentType = contentType
        self.expectedContentTyp = expectedContentType

