from dateutil import parser as dateParser
from source.ReadWriteLock import RWLock


def parseMoreLinks(links, language):
    parsedLinks = []
    for link in links:
        try:
            parsedLinks.append(MoreLink(link['name'], link['link'], int(link['importance']), language))
        except KeyError as e:
            if 'importance' in str(e):
                parsedLinks.append(MoreLink(link['name'], link['link'], 1000, language))
            else:
                raise e
    parsedLinks = sorted(parsedLinks, key=(lambda x: x.getImportance()))
    return parsedLinks

class MoreModel:

    def __init__(self, moreDict):
        self._lock = RWLock()
        try:
            self.timeStamp = dateParser.parse(moreDict['linksLastChanged'])
            self.language = moreDict['language']
            self.links = parseMoreLinks(moreDict['links'], self.language)
        except ValueError as e:
            pass

    def getTime(self):
        self._lock.acquire_read()
        try:
            return self.timeStamp
        finally:
            self._lock.release()
    
    def getLinks(self):
        self._lock.acquire_read()
        try:
            if self.links == None:
                return []
            else:
                return self.links
        finally:
            self._lock.release()
    
    def getLanguage(self):
        self._lock.acquire_read()
        try:
            if self.language is None:
                return ""
            else:
                return self.language
        finally:
            self._lock.release()


class MoreLink:

    # importance 0 is most important, getting less important with higher numbers
    def __init__(self, name, link, importance, language):
        self._name = name
        self._link = link
        self._importance = importance
        self._language = language

    def getName(self):
        return self._name

    def getLink(self):
        return self._link

    def getImportance(self):
        return self._importance

    def __eq__(self, other):
        if isinstance(other, MoreLink):
            return self._name == other._name and self._link == other._link and self._language == other._language and \
                   self._importance == other._importance
        else:
            return False

    def __lt__(self, other):
        return self._importance < other._importance