import json
from dateutil import parser as dateParser
from source.ReadWriteLock import RWLock


mapLock = RWLock()


class MapModel:
    def __init__(self, filepath, updateTime):
        self.filepath = filepath
        self.updateTime = updateTime

    def getFilepath(self):
        mapLock.acquire_read()
        try:
            return self.filepath
        finally:
            mapLock.release()

    def getCoordinateList(self):
        """
        :return: the map data as a list
        """
        mapLock.acquire_read()
        try:
            with open(self.filepath, 'r') as f:
                mapJSONString = f.read()
                mapJSONDict = json.loads(mapJSONString)
                mapData = mapJSONDict['mapInfo']
                return mapData
        finally:
            mapLock.release()

    def getUpdateTime(self):
        mapLock.acquire_read()
        try:
            return self.updateTime
        finally:
            mapLock.release()

    def update(self):
        """
        updates the update time by reading the json file and storing the value for updateTime
        """
        mapLock.acquire_write()
        try:
            with open(self.filepath, 'r') as f:
                mapJSONString = f.read()
                mapJSONDict = json.loads(mapJSONString)
                updateTime = dateParser.parse(mapJSONDict['updateTime'])
                self.updateTime = updateTime
        finally:
            mapLock.release()

