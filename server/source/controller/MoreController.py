import json
from os.path import isfile, join
from os import listdir
from source.models.MoreModel import MoreModel
from source.views.MoreView import MoreView
from source.Constants import MORE_LINKS_LOCATION


class MoreController:

    def __init__(self):
        self.MORE_LINKS_LOCATION = MORE_LINKS_LOCATION
        self.moreView = MoreView()

    def getMoreFile(self, language, path):
        """
        @param language: the language of the file to fetch
        @param path: path containing the location info files
        @return: List of strings, each one the content of a file
        """
        # Gather all files in folder locationPath
        fileList = [f for f in listdir(path) if isfile(join(path, f))]

        for fileName in fileList:
            with open(join(path, fileName), 'r') as f:
                as_dict = json.load(f)
                if as_dict['language'] == language:
                    return MoreModel(as_dict)

            if not f.closed:
                raise IOError
            
        return MoreModel({})
    
    def retrieveMore(self, language, time):
        """
        @return: the "More" links as a dict
        """
       
        try:
            model = self.getMoreFile(language, self.MORE_LINKS_LOCATION)
            if time is None or model.getTime() > time:
                return self.moreView.toJSON(model)
            else:
                return json.dumps('still up to date')

        except ValueError as e:
            raise e
