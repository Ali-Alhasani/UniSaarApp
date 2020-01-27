from dateutil import parser as dateParser
from source.ReadWriteLock import RWLock


class MoreModel:

    def __init__(self, moreDict):
        self.raw = moreDict
        self._lock = RWLock()
        try:
            self.timeStamp = dateParser.parse(moreDict['linksLastChanged'])
            self.links = moreDict['links']
            self.language = moreDict['language']
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
                return {}
            else:
                return self.links
        finally:
            self._lock.release()
    
    def getLanguage(self):
        self._lock.acquire_read()
        try:
            if self.language == None:
                return ""
            else:
                return self.language
        finally:
            self._lock.release()
    
    def getRaw(self):
        self._lock.acquire_read()
        try:
            if self.raw == None:
                return {}
            else:
                return self.raw
        finally:
            self._lock.release()
    