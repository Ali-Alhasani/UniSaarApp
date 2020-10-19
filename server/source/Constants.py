from datetime import timedelta
from os.path import abspath, join

#SERVER_ADDRESS = 'localhost'
SERVER_ADDRESS = 'unisaar-test.cs.uni-saarland.de'
SERVER_PORT = 3000

# News and Events
SEMESTER_TERMINE_LINK = 'https://www.uni-saarland.de/studium/organisation/termine.html'
SEMESTER_TERMINE_CATEGORY_STRING = 'Semestertermine'
GERMAN_NEWS_STRING = 'Deutsche Neuigkeiten'
ENGLISH_NEWS_STRING = 'English News'
FRENCH_NEWS_STRING = 'Actualités Françaises'
GERMAN_EVENT_STRING = 'Deutsche Veranstaltungen'
ENGLISH_EVENT_STRING = 'English Events'
FRENCH_EVENT_STRING = 'Événements Français'

NEWSFEED_LANGUAGES = ['de', 'en', 'fr']
ACADEMIC_CALENDAR_FOLDER = 'academic_calendar/'


def getCachedEventsLocation(language: str):
    if language == 'de':
        return CACHED_EVENTS_LOCATION_DE
    elif language == 'en':
        return CACHED_EVENTS_LOCATION_EN
    elif language == 'fr':
        return CACHED_EVENTS_LOCATION_FR


CACHED_EVENTS_LOCATION_DE = abspath(join('.', 'cached_events/events_de.cache'))
CACHED_EVENTS_LOCATION_EN = abspath(join('.', 'cached_events/events_en.cache'))
CACHED_EVENTS_LOCATION_FR = abspath(join('.', 'cached_events/events_fr.cache'))


HTML_TEMPLATE_DIRECTORY = abspath(join('.', 'templates'))
WEBVIEW_NEWS_TEMPLATE = 'webview_news.html'
WEBVIEW_EVENTS_TEMPLATE = 'webview_event.html'
WEBVIEW_ERROR_TEMPLATE = 'errorpage.html'
IMAGE_ERROR_DIRECTORY = abspath(join('.', 'images'))+'/'
IMAGE_ERROR_URL = '/error_image'

PRODID_CORP = 'Uni_Saar'
PRODID_PROD = 'Uni_Saar_App_2.0'
PRODID = '-//{corp}//{prod}//'.format(corp=PRODID_CORP, prod=PRODID_PROD)
ICS_DOMAIN = 'http://' + SERVER_ADDRESS + ':' + str(SERVER_PORT)
ICS_BASE_LINK = 'http://' + SERVER_ADDRESS + ':' + str(SERVER_PORT) + '/events/iCal?id='

# Mensa
LOCATION_INFO_PATH = abspath(join('source', 'location_info_files'))
MENSA_LANGUAGES = ['de', 'en', 'fr']

# Map
MAP_FOLDER = abspath(join('.', 'source', 'map_data'))
MAP_PATH = join(MAP_FOLDER, 'campus_map_data')

# Directory
HELPFUL_NUMBERS_PATH = abspath(join('source', 'helpful_number_files'))
DIRECTORY_CACHE_THRESHOLD = timedelta(hours=1)
DIRECTORY_IMAGE_PATH = abspath(join('source', 'directory_images'))
DIRECTORY_IMAGE_BASE_LINK = 'http://' + SERVER_ADDRESS + ':' + str(SERVER_PORT) + '/directory/image?name='

# More
MORE_LINKS_LOCATION = abspath(join('source', 'links_for_more_tab'))

# Update intervals
NEWSFEED_UPDATE_INTERVAL_IN_SECONDS = timedelta(minutes=60)
MENSA_UPDATE_THRESHOLD_WORKING_HOURS = timedelta(minutes=15)
MENSA_UPDATE_THRESHOLD_NIGHT = timedelta(minutes=90)
NEWSFEED_UPDATE_THRESHOLD = timedelta(minutes=60)
MAP_UPDATE_THRESHOLD = timedelta(hours=1)
HELPFUL_NUMBERS_THRESHOLD = timedelta(hours=1)

# sleep interval in seconds in case of errors
ERROR_SLEEP_INT = 10
MAX_RETRY_BEFORE_LONG_WAIT = 5
ERROR_LONG_SLEEP = 30*60
