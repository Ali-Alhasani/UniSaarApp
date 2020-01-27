import json
from datetime import datetime
from source.models.DirectoryModel import DetailedPerson, GeneralPerson, HelpfulNumber, FunctionDetails


def generalPersonToJSON(generalPerson: GeneralPerson) -> dict:
    """
    Creates a dictionary of a GeneralPerson to be packed into a JSON
    @param generalPerson: GeneralPerson
    @return: dictionary of the form: { "name": name, "title": title, "pid": pid }
    """
    return {"name": generalPerson.getName(), "title": generalPerson.getTitle(), "pid": generalPerson.getPID()}


class DirectoryView:

    def showSearchResults(self, searchResultList: list, itemCount: int, hasNextPage: bool) -> str:
        """
        Takes a list of GeneralPerson [gp1, gp2, ...] and creates a JSON of the form:
       { "itemCount": itemCount, "hasNextPage": hasNextPage,
         "results": [ { "name": name1, "title": title1, "pid": pid1 },
                      { "name": name2, "title": title2, "pid": pid2 }, ... ] }
        If searchResultList is None, the user hasn't narrowed down the search enough, i.e. there are still too many
        results. In this case, the return value will be a JSON of the form:
        "Too many results"
        @param searchResultList: list of GeneralPerson
        @param itemCount: int, number of results
        @param hasNextPage: bool
        @return: a JSON of the form { "itemCount": itemCount, "hasNextPage": hasNextPage,
                                      "results": [ { "name": name1, "title": title1, "pid": pid1 },
                                                   { "name": name2, "title": title2, "pid": pid2 }, ... ] }
                 or
                    "Too many results"
        """
        if searchResultList is None:
            return json.dumps("Too many results")

        # remove ws after separator for compact representation
        return json.dumps({"itemCount": itemCount, "hasNextPage": hasNextPage,
                           "results": [generalPersonToJSON(gp) for gp in searchResultList]}, separators=(',', ':'))

    def personFunctionToJSON(self, function: FunctionDetails):
        """
        Creates a dict from FunctionDetails to be packed into a JSON.
        @param function: FunctionDetails
        @return: a JSON of the form:
            { "fDepartment": fDepartment, "fFunction": fFunction, "fStart": fStart, "fEnd": fEnd,
              "fOffice": fOffice, "fBuilding": fBuilding, "fStreet": fStreet, "fPostalCode": fPostalCode,
              "fCity": fCity, "fPhone": fPhone, "fFax": fFax, "fMail": fMail, "fWebpage": fWebpage }
        """
        return { 'fDepartment': function.getDepartment(), 'fFunction': function.getFunction(),
                 'fStart': function.getStart(), 'fEnd': function.getEnd(), 'fOffice': function.getRoom(),
                 'fBuilding': function.getBuilding(), 'fStreet': function.getStreet(),
                 'fPostalCode': function.getPostalCode(), 'fCity': function.getCity(),
                 'fPhone': function.getPhone(), 'fFax': function.getFax(), 'fMail': function.getMail(),
                 'fWebpage': function.getWebpage()}

    def showPersonDetails(self, person: DetailedPerson, language: str) -> str:
        """
        Takes a DetailedPerson and creates a JSON
        @param person: DetailedPerson
        @param language: str, used for fields whose value should be in the corresponding language (i.e. gender)
        @return: a JSON of the form:
        { "firstname": firstname, "lastname": lastname, "title": academicTitle, "gender": gender,
         "officeHour": officeHour, "remark": remark, "office": office, "building": building, "street": street,
         "postalCode": postalCode, "city": city, "phone": phone, "fax": fax, "mail": mail, "webpage": webpage,
         "imageLink": imageLink,
         "functions": [ { "fDepartment": fDepartment, "fFunction": fFunction, "fStart": fStart, "fEnd": fEnd,
                           "fOffice": fOffice, "fBuilding": fBuilding, "fStreet": fStreet, "fPostalCode": fPostalCode,
                           "fCity": fCity, "fPhone": fPhone, "fFax": fFax, "fMail": fMail, "fWebpage": fWebpage
                         }, { ... } ]
        }
        """
        personDict = {"firstname": person.getFirstname(), "lastname": person.getLastname(),
                      "title": person.getAcademicTitle(), "gender": person.getGender(language=language),
                      "officeHour": person.getOfficeHour(), "remark": person.getRemark(), "office": person.getOffice(),
                      "building": person.getBuilding(), "street": person.getStreet(),
                      "postalCode": person.getPostalCode(), "city": person.getCity(),
                      "phone": person.getPhone(), "fax": person.getFax(), "mail": person.getMail(),
                      "webpage": person.getWebpage(), "imageLink": person.getImageLink()}
        personDict['functions'] = [self.personFunctionToJSON(func) for func in person.getFunctions()]

        return json.dumps(personDict, separators=(',', ':'))  # remove ws after separator for compact representation

    def helpfulNumberToJSON(self, helpfulNumber: HelpfulNumber) -> str:
        """
        Takes a HelpfulNumber and creates a dict to be packed into a JSON
        @param helpfulNumber: HelpfulNumber
        @return: dictionary of the form: {"name": name, "number": number, "link": link, "mail": mail}
            where mail and link are optional
        """
        returnDict = {'name': helpfulNumber.getName(), 'number': helpfulNumber.getNumber()}

        if not helpfulNumber.getLink() == '':
            returnDict['link'] = helpfulNumber.getLink()

        if not helpfulNumber.getMail() == '':
            returnDict['mail'] = helpfulNumber.getMail()

        return returnDict

    def showHelpfulNumbers(self, helpfulNumbers: list, numbersLastChanged: datetime) -> str:
        """
        Takes a list of HelpfulNumber and creates a JSON
        @param helpfulNumbers: list of HelpfulNumber
        @return: JSON of the form:
            { 'numbersLastChanged': numLastChanged,
              'numbers': [ {"name": name, "number": number, "link": link, "mail": mail}, ... ] }
        where link and mail are optional or "still up to date" if the client's helpful numbers are still up to date
        """
        helpfulNumbers = [self.helpfulNumberToJSON(hn) for hn in helpfulNumbers]

        # remove ws after separator for compact representation
        return json.dumps({'numbersLastChanged': str(numbersLastChanged), 'numbers': helpfulNumbers},
                          separators=(',', ':'))

    def clientUpToDate(self) -> str:
        """
        Returns a json with the string "client still up to date".
        @return: str
        """
        return json.dumps('client still up to date')
