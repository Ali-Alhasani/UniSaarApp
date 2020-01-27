import json


class MoreView:

    def toJSON(self, more):
        return json.dumps(more.getRaw())

