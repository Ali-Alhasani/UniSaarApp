from source.models.NewsAndEventsModel import NewsAndEventsModel


class NewsModel (NewsAndEventsModel):

    def __init__(self, title, publishedDate, id, link, categories, description: str, content: str, imageLink=None):
        super().__init__(title, publishedDate, id, link, categories, description, content, imageLink)

    def __eq__(self, other):
        if isinstance(other, NewsModel):
#            b = (self.title == other.title and self.publishedDate == other.publishedDate
#                    and self.link == other.link and self.categories == other.categories
#                    and self.description == other.description and self.content == other.content
#                    and self.imageLink == other.imageLink)
            b = (self.title == other.title and self.publishedDate == other.publishedDate)
            return b
        else:
            return False

    def __hash__(self):
        return hash((self.title, self.publishedDate))

    def __copy__(self):
        newone = NewsModel(self.title, self.publishedDate, self.id, self.link, self.categories, self.description,
                           self.content, self.imageLink)
        return newone
