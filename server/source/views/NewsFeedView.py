import json  # to encode items as JSON
from source.models.EventModel import EventModel
from source.models.NewsModel import NewsModel
import jinja2
from icalendar import Calendar, Event
from datetime import datetime
from source.Constants import *



class NewsFeedView:


    def __init__(self):
        self.loader = jinja2.FileSystemLoader(HTML_TEMPLATE_DIRECTORY)
        self.imageLoader = jinja2.FileSystemLoader(IMAGE_ERROR_DIRECTORY)
        self.env1 = jinja2.Environment(loader=self.imageLoader)
        self.env = jinja2.Environment(loader=self.loader)
        self.env1.globals['IMAGE_ERROR_DIRECTORY'] = 'IMAGE_ERROR_DIRECTORY'

        self.news_template = self.env.get_template(WEBVIEW_NEWS_TEMPLATE)
        self.event_template = self.env.get_template(WEBVIEW_EVENTS_TEMPLATE)
        self.error_template = self.env.get_template(WEBVIEW_ERROR_TEMPLATE)


    def newsModelHeaderToJSON(self, newsModel):
        """
        Places a representation of passed newsAndEventsModel into the dictionary
        @param newsModel: the model to be encoded
        @param dictionary: the dictionary to be loaded
        """
        categoryDict = {}
        for category in newsModel.getCategories():
            categoryDict[category.getID()] = category.getName()
        sendDict = {
            "isEvent": False,
            "publishedDate": str(newsModel.getPublishedDate()),
            "title": newsModel.getTitle(),
            "categories": categoryDict,
            "link": newsModel.getLink(),
            "description": newsModel.getDescription(),
            "imageURL": newsModel.getImageLink(),
            "id": newsModel.getID()
        }
        return sendDict

    def eventModelHeaderToJSON_NewsMainScreen(self, eventModel):
        categoryDict = {}
        for category in eventModel.getCategories():
            categoryDict[category.getID()] = category.getName()
        sendDict = {
            "isEvent": True,
            "publishedDate": str(eventModel.getPublishedDate()),
            "happeningDate": str(eventModel.getHappeningDate()),
            "title": eventModel.getTitle(),
            "categories": categoryDict,
            "link": eventModel.getLink(),
            "description": eventModel.getDescription(),
            "imageURL": eventModel.getImageLink(),
            "id": eventModel.getID()
        }
        return sendDict

    def eventModelHeaderToJSON_EventsMainScreen(self, eventModel):
        categoryDict = {}
        for category in eventModel.getCategories():
            categoryDict[category.getID()] = category.getName()
        sendDict = {
            "publishedDate": str(eventModel.getPublishedDate()),
            "happeningDate": str(eventModel.getHappeningDate()),
            "title": eventModel.getTitle(),
            "categories": categoryDict,
            "link": eventModel.getLink(),
            "description": eventModel.getDescription(),
            "imageURL": eventModel.getImageLink(),
            "id": eventModel.getID()
        }
        return sendDict

    def newsFeedHeadersToJSON(self, news, itemCount, lastChanged, hasNextPage):
        """
        Encodes all NewsAndEventsModels within the list news as JSON
        :param itemCount: the number of items for the filter settings
        :param hasNextPage: whether for the filter settings there exists a next page (for continuous scrolling)
        :param lastChanged: timestamp of the last time something in the news categories changed
        :param news: a list of NewsAndEventModels to convert into JSON
        """
        to_send = {"itemCount": itemCount,
                   "hasNextPage": hasNextPage,
                   "categoriesLastChanged": str(lastChanged), "items": []}
        for newsItem in news:
            if (isinstance(newsItem, NewsModel)):
                to_send["items"].append(self.newsModelHeaderToJSON(newsItem))
            elif (isinstance(newsItem, EventModel)):
                to_send["items"].append(self.eventModelHeaderToJSON_NewsMainScreen(newsItem))
        return json.dumps(to_send)

    def toWebViewNewsItem(self, newsItem):
        """
         @param: newsTemplate: It is a dictionary of different items from the news JSON. It has,
        title: that describes the title of the news,
        category: that has the category of the event or the name 'news' itself,
        publishedDate: that says the data on which the news information is published,
        image: if the news item has an attached image,
        description: that has a short description of the news,
        content: that has more information about a particular news,
        this dictionary is then rendered into a web page using jinja. For more documentation, open https://jinja.palletsprojects.com/en/2.10.x/
        @param newsItem: to be encoded as HTML
        """
        newsTemplate = dict(title=newsItem.getTitle(),
                            category=newsItem.getCategoryString(),
                            publishedDate=newsItem.getPublishedDate(),
                            image=newsItem.getImageLink(),
                            description=newsItem.getDescription(),
                            content=newsItem.getContent(),
                            link=newsItem.getLink()
                            )
        renderedTemplate = self.news_template.render(newsTemplate=newsTemplate)
        return renderedTemplate

    def toWebViewEventItem(self, eventItem, language):
        """
        @param: eventTemplate: It is a dictionary of different items from the events JSON. It has,
        title: that describes the title of the event,
        category: that has the category of the event or the name 'event' itself,
        publishedDate: that says the data on which the event information is published,
        happeningDate: specific to events category tha mentions when the event is happening,
        image: if the event has any kind of image attached,
        description: that has a short description of the event,
        content: that has more information about a particular event,
        this dictionary is then rendered into a web page using jinja.
        For more documentation, open https://jinja.palletsprojects.com/en/2.10.x/
        @param eventItem: to be encoded as HTML
        @param language: str
        """
        icsLink = ICS_BASE_LINK + str(eventItem.getID())
        eventTemplate = dict(title=eventItem.getTitle(),
                             category=eventItem.getCategoryString(),
                             happeningDate=eventItem.getHappeningDate(),
                             image=eventItem.getImageLink(),
                             description=eventItem.getDescription(),
                             content=eventItem.getContent(),
                             link=eventItem.getLink(),
                             ics=icsLink,
                             language=language
                             )
        renderedTemplate = self.event_template.render(eventTemplate=eventTemplate)
        return renderedTemplate

    def toJSONEvents(self, events, lastChanged):
        """
        Returns the JSON format of a set of events
        @param events: the events to be encoded as JSON
        @:param lastChanged: the last time the categories of the events changed
        """
        to_send = {"eventCategoriesLastChanged": str(lastChanged), "items": []}
        # check to make sure events contains only EventModels, then encode
        for e in events:
            assert (isinstance(e, EventModel)), "Each element in events should be an EventModel!"
            to_send["items"].append(self.eventModelHeaderToJSON_EventsMainScreen(e))
        return json.dumps(to_send)

    def toJSONCategories(self, categories):
        """
        :param categories: a set of categories, where each category is a string
        :return: a json with a list of all categories
        """
        categoryList = []
        for cat in categories:
            categoryList.append({"id": cat.getID(), "name": cat.getName()})
        categoryList = sorted(categoryList, key=lambda x: x['id'])
        return json.dumps(categoryList)

    def toICalEvent(self, event: EventModel):
        """
        Creates a iCal string containing just one event
        @param event: EventModel
        @return: str
        """
        cal = Calendar()

        # add required properties to calendar
        cal.add('prodid', PRODID)
        cal.add('version', '2.0')

        # create ical event
        ev = Event()

        # add required properties to event
        ev.add('uid', '{time}-{eventID}@{domain}'.format(time=datetime.utcnow().isoformat(), eventID=event.getID(),
                                                         domain=ICS_DOMAIN))
        ev.add('dtstamp', datetime.utcnow())
        startTime = event.getHappeningDate() if event.getHappeningTime() is None else event.getHappeningTime()
        ev.add('dtstart', startTime)

        # make the event transparent (in order not to block the calendar slot)
        ev.add('transp', 'TRANSPARENT')

        # add optional parameters
        title = event.getTitle()
        description = event.getDescription()
        link = event.getLink()
        categories = event.getCategories()

        if not title == '':
            ev.add('summary', title)
        if not description == '':
            ev.add('description', description)
        if not link == '':
            ev.add('link', link)
        if not len(categories) == 0:
            ev.add('categories', [cat.getName() for cat in categories])

        cal.add_component(ev)

        return cal.to_ical()

    def toWebViewError(self, language):
        errorimage = IMAGE_ERROR_DIRECTORY + 'owl_error.png'
        errorTemplate = dict(language=language,
                             errorimage=errorimage)
        renderedTemplate = self.error_template.render(errorTemplate=errorTemplate)
        return renderedTemplate



