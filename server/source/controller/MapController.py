from source.models.MapModel import MapModel
from source.views.MapView import MapView
from source.Constants import MAP_PATH
from datetime import datetime
import json


class MapController:

    def __init__(self):
        """
        the filepath is a string of a filepath to a directory where all map data files are stored
        """
        self.filepath = MAP_PATH
        self.mapModel = MapModel(self.filepath, datetime.now())
        self.mapModel.update()
        self.mapView = MapView()

    def updateMap(self):
        """
        will be called periodically from the server to update the map
        """
        self.mapModel.update()

    def retrieveMap(self, lastUpdateTime=None):
        """
        :returns a json of the map data if lastUpdateTime is older that map.updateTime, otherwise an empty json
        """
        if (lastUpdateTime is None) or (lastUpdateTime < self.mapModel.getUpdateTime()):
            return self.mapView.toJSON(self.mapModel)
        else:
            return json.dumps([])
