import json


def linkToDict(link):
    return {'name': link.getName(), 'link': link.getLink()}


class MoreView:

    def toJSON(self, more):
        links = more.getLinks()
        dictLinks = [linkToDict(link) for link in links]
        language = more.getLanguage()
        lastUpdated = more.getTime()
        return json.dumps({'linksLastChanged': str(lastUpdated),
                           'language': language,
                           'links': dictLinks})

