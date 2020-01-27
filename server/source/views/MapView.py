from source.models.MapModel import MapModel
import json


class MapView:

    def toJSON(self, mapModel: MapModel):
        coordinateList = mapModel.getCoordinateList()
        return json.dumps(coordinateList)

