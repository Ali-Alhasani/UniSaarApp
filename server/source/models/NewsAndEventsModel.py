class NewsAndEventsModel:

    def __init__(self, title, publishedDate, id, link="", categories=None, description: str = "", content: str = "",
                 imageLink=""):
        """
        construct a NewsAndEventsModel object containing the title, the release date, a link to the item,
        the associated categories, a description, the content and optionally a link to an image
        should not need a lock, since it should never be written to except for initialization
        """
        if categories is None:
            categories = []
        self.title = title
        self.categories = categories
        self.link = link
        self.publishedDate = publishedDate
        self.description = description
        self.content = content
        self.imageLink = imageLink
        self.id = id

    def getID(self):
        return self.id

    def getTitle(self):
        if self.title is None:
            return ""
        return self.title

    def getCategoryString(self):
        categoryString = ""
        for cat in self.getCategories():
            categoryString += cat.getName() + ', '
        categoryString = categoryString.strip(', ')
        return categoryString

    def getCategories(self):
        """
        :return: the categories as a list associated to this item
        """
        if self.categories is None:
            return []
        return list(self.categories)

    def getLink(self):
        """
        :return: the link to the item
        """
        if self.link is None:
            return ""
        return self.link

    def getContent(self):
        """
        :return: the content of the news or event item
        """
        if self.content is None:
            return ""
        return self.content

    def getDescription(self):
        """
        :return: the description of this news or events item
        """
        if self.description is None:
            return ""
        return self.description

    def getPublishedDate(self):
        """
        :return the release date of the item
        """
        return self.publishedDate

    def getImageLink(self):
        """
        :return: the image associated to this news or events item
        """
        if self.imageLink is None:
            return ""
        return self.imageLink

    def __lt__(self, other):
        return self.publishedDate < other.publishedDate

    def removeCategories(self, categories):
        newCats = set()
        for cat in self.categories:
            if cat not in categories:
                newCats.add(cat)
        self.categories = newCats

