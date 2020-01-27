from source.models.NewsAndEventsModel import NewsAndEventsModel


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

