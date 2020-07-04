from source.models.NewsAndEventsModel import NewsAndEventsModel
from CategoryModel import categoryFromCache
from datetime import datetime
from dateutil import parser as dateParser

def eventFromCache(eventCache):
    """
    @param eventCache: a dictionary as returned by Event.toCache()
    @return: an Event that has the same attributes as the original event that was cached
    """
    if eventCache['happeningTime'] is not None:
        return EventModel(eventCache['title'], datetime.strptime(eventCache['happeningDate'], "%Y-%m-%d").date(),
                          datetime.strptime(eventCache['publishedDate'], "%Y-%m-%d").date(),
                          int(eventCache['id']), eventCache['link'],
                          set([categoryFromCache(catCache) for catCache in eventCache['categories']]),
                          eventCache['description'], eventCache['content'], eventCache['imageLink'],
                          dateParser.parse(eventCache['happeningTime']))
    else:
        return EventModel(eventCache['title'], datetime.strptime(eventCache['happeningDate'], "%Y-%m-%d"),
                          datetime.strptime(eventCache['publishedDate'], "%Y-%m-%d"),
                          eventCache['id'], eventCache['link'],
                          set([categoryFromCache(catCache) for catCache in eventCache['categories']]),
                          eventCache['description'], eventCache['content'], eventCache['imageLink'])


class EventModel (NewsAndEventsModel):

    def __init__(self, title: str, happeningDate, publishedDate, id, link, categories, description: str, content: str,
                 imageLink=None, happeningTime=None):
        self.happeningDate = happeningDate
        self.happeningTime = happeningTime
        super().__init__(title, publishedDate, id, link, categories, description, content, imageLink)

    def getHappeningDate(self):
        return self.happeningDate

    def getHappeningTime(self):
        return self.happeningTime

    def toCache(self):
        eventDict = {
            'title': self.title,
            'happeningDate': str(self.happeningDate),
            'publishedDate': str(self.publishedDate),
            'id': self.id,
            'link': self.link,
            'categories': [cat.toCache() for cat in self.categories],
            'description': self.description,
            'content': self.content,
            'imageLink': self.imageLink,
            'happeningTime': str(self.happeningTime)
        }
        return eventDict

    def __eq__(self, other):
        if isinstance(other, EventModel):
            return (self.title == other.title and self.happeningDate == other.happeningDate
                    and self.link == other.link and self.categories == other.categories
                    and self.description == other.description and self.content == other.content
                    and self.imageLink == other.imageLink)
        else:
            return False

    def __hash__(self):
        return hash((self.happeningDate, self.title))

    def __copy__(self):
        newone = EventModel(self.title, self.happeningDate, self.publishedDate, self.id, self.link, self.categories,
                            self.description,
                            self.content, self.imageLink, self.happeningTime)
        return newone

