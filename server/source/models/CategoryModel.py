def categoryFromCache(catCache):
    """
    takes a dictionary of the form {'name': name, 'id': id} and returns the corresponding category
    """
    return Category(catCache['name'], int(catCache['id']))


class Category:
    # does not have to be locked, since it is never written to, only when creating
    def __init__(self, name, categoryID):
        self.name = name
        self.categoryID = categoryID

    def getName(self):
        return self.name

    def getID(self):
        return self.categoryID

    def toCache(self):
        catDict ={
            'name': self.name,
            'id': self.categoryID
        }
        return catDict

    def __eq__(self, other):
        return self.name == other.name

    def __hash__(self):
        return hash(self.name)
