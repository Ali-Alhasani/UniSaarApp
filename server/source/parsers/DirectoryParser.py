import json
from bs4 import BeautifulSoup, Tag, Comment
from urllib.parse import urlparse, parse_qs
from source.models.DirectoryModel import DetailedPerson, GeneralPerson, HelpfulNumber, FunctionDetails


def isErgListEntryName(tag: Tag) -> bool:
    """
    Used for BeautifulSoup.find_all().
    Checks if a tag has css class 'erg_list_entry'. If so, checks if its first div tag has class 'erg_list_label'
    and if this tag contains string 'Name:'.
    Returns True iff these conditions are met (i.e. if the tag in question contains a search result name)
    @param tag: html-tag
    @return: bool
    """
    if not (tag.name == 'div' and tag.has_attr('class') and 'erg_list_entry' in tag['class']):
        return False

    div = tag.find(name='div')

    if div is None or div.find(string=True) is None:
        return False

    return 'erg_list_label' in div['class'] and div.string == 'Name:'


def createGeneralPersonFromSearchResult(tag: Tag) -> GeneralPerson:
    """
    Creates a GeneralPerson from a html tag. This has to be a div tag inside which there is a 'a' tag that has a link
    attribute that contains the query parameter 'personal.pid' with value pid. Inside the 'a' tag, there also needs to
    be the person's name
    @param tag: html-tag
    @return: GeneralPerson
    """
    a = tag.a
    link = a['href']

    # parse the link for the pid
    u = urlparse(link)
    q = parse_qs(u.query)
    pid = int(q['personal.pid'][0])

    # get the name and title
    nameList = a.string.splitlines()
    nameList = [m for m in [n.strip() for n in nameList] if not m == '']
    title = " ".join(nameList[:-2]) if len(nameList) > 2 else ''
    firstname = nameList[-2] if len(nameList) >= 2 else ''
    lastname = nameList[-1] if len(nameList) >= 1 else ''

    return GeneralPerson(firstname=firstname, lastname=lastname, title=title, pID=pid)


def findTableHeader(tag: Tag, keyword: str) -> bool:
    """
    Checks, if a tag is a tableheader and if it contains a string containing the keyword
    @param tag: html-tag
    @param keyword: str
    @return: bool
    """
    text = tag.find_all(string=True)

    text = [t.strip() for t in text]

    return tag.name == 'th' and keyword in text


def getDataFromTable(tag: Tag, keyword: str, occurrence: int = 0) -> str:
    """
    Parses a html table on a lsf page containing details of a person. Looks for a table header containing keyword
    and returns the corresponding table data (the tables in the lsf have only one data entry per header). If occurrence
    is set to i, returns the data corresponding to the i-th occurrence of the keyword.
    Returns None, if the header is not found
    @param tag: html-tag
    @param keyword: str
    @param occurrence: int, optional, default 0
    @return: str
    """
    decisionFunction = lambda t: findTableHeader(tag=t, keyword=keyword)
    headerList = tag.find_all(decisionFunction)

    if len(headerList) <= occurrence:
        return None

    header = headerList[occurrence]

    # the value is in the next element after the header, need next_sibling twice because the header.next_sibling is the
    # newline after the header element
    valueTag = header.next_sibling.next_sibling
    value = ''
    for v in [string.strip() for string in valueTag.find_all(string=lambda text: not isinstance(text, Comment))]:
        if not v == '':
            value = v

    return value


class DirectoryParser:

    def parseWebpageForPIDs(self, webpage: str):
        """
        Parses the html of a webpage returned in a search query for people and returns a list of GeneralPerson and the
        number of results
        @param webpage: str, html as returned by a lsf search for a person
        @return: tuple with first entry list of GeneralPerson or None if there are too many search results
                 and second entry number of results found
                 returns (None, 0) if there are either too many results to display or the search query was too short
        """
        soup = BeautifulSoup(webpage, features="html.parser")

        # If there are too many search results, the search requires more information
        # in this case, return None 
        # to distinguish this case, look for the h1 tag's content
        if soup.find(name='h1').string in ['Bitte geben Sie mehr Suchbegriffe ein',
                                           'Bitte spezifizieren Sie Ihre Suchanfrage']:
            raise UnspecificSearchQueryException('')
            #return None, 0

        # Get the number of search results
        # We assume that there is only one div tag with css-class 'InfoLeiste'
        # This tag contains a string whose first word is the number of hits
        count = int(soup.find(name='div', class_='InfoLeiste').string.split()[0])

        # Gather the search results

        # All search results are contained in div tags with css-class 'erg_list_entry'
        # To get only the names and pID, we check the contained div tag with class 'erg_list_label'
        # If this tag contains the string 'Name:', we want to keep the 'erg_list_entry' tag.
        # We know, that we only look for count many results.
        searchResultList = soup.find_all(isErgListEntryName, limit=count)

        # Create a GeneralPerson from each search result and return this list
        return [createGeneralPersonFromSearchResult(sr) for sr in searchResultList], count

    def parsePersonDetail(self, webpage: str):
        """
        Parses the html of a webpage containing a persons details. Returns a DetailedPerson
        @param webpage: str, html as returned by the detail view of a person in the lsf person search
        @return: DetailedPerson
        """
        # for some reason, the lsf webpage has a bad character (a comment of the form <!-- text --!>)
        # this breaks BeautifulSoup and thus has to be cleaned up first
        webpage = webpage.replace('--!>', '-->')

        soup = BeautifulSoup(webpage, features="html.parser")

        # parse the webpage for the relevant information
        # look for the tables 'Grunddaten' and 'Dienstadresse'

        # 'Grunddaten'
        baseDataTable = soup.find(name='table', summary='Grunddaten zur Veranstaltung')

        if baseDataTable is None:
            firstname = ''
            lastname = ''
            academicTitle = ''
            officeHour = ''
            remarks = ''
            gender = ''
        else:
            firstname = getDataFromTable(baseDataTable, 'Vorname')
            lastname = getDataFromTable(baseDataTable, 'Nachname')
            academicTitle = getDataFromTable(baseDataTable, 'Akad. Grad')
            officeHour = getDataFromTable(baseDataTable, 'Sprechzeit')
            remarks = getDataFromTable(baseDataTable, 'Bemerkung')
            gender = getDataFromTable(baseDataTable, 'Geschlecht')

        # 'Dienstadresse'
        contactDataTable = soup.find(name='table', summary='Angaben zur Dienstadresse')

        if contactDataTable is None:
            postalCode = ''
            city = ''
            street = ''
            office = ''
            building = ''
            phone = ''
            fax = ''
            mail = ''
            website = ''
        else:
            postalCode = getDataFromTable(contactDataTable, 'PLZ')
            city = getDataFromTable(contactDataTable, 'Ort')
            street = getDataFromTable(contactDataTable, 'Straße')
            office = getDataFromTable(contactDataTable, 'Dienstzimmer')
            building = getDataFromTable(contactDataTable, 'Gebäude')
            phone = getDataFromTable(contactDataTable, 'Telefon')
            fax = getDataFromTable(contactDataTable, 'Fax')
            mail = getDataFromTable(contactDataTable, 'E-Mail-Adresse')
            website = getDataFromTable(contactDataTable, 'Hyperlink')

        # 'Funktionen'
        functions = []
        functionTable = soup.find(name='table', summary='Funktionen')

        if functionTable is not None:
            functionCount = len(functionTable.find_all(name='td', headers='basic_1'))

            for i in range(functionCount):
                fDepartment = functionTable.find_all(name='td', headers='basic_1')[i].text.strip()
                fFunction = functionTable.find_all(name='td', headers='basic_2')[i].text.strip()
                fStart = functionTable.find_all(name='td', headers='basic_3')[i].text.strip()
                fEnd = functionTable.find_all(name='td', headers='basic_4')[i].text.strip()

                fPostalCode = getDataFromTable(functionTable, 'PLZ', i)
                fCity = getDataFromTable(functionTable, 'Ort', i)
                fStreet = getDataFromTable(functionTable, 'Straße', i)
                fRoom = getDataFromTable(functionTable, 'Raum', i)
                fBuilding = getDataFromTable(functionTable, 'Gebäude', i)
                fPhone = getDataFromTable(functionTable, 'Telefon', i)
                fFax = getDataFromTable(functionTable, 'Fax', i)
                fMail = getDataFromTable(functionTable, 'E-Mail-Adresse', i)
                fWebpage = getDataFromTable(functionTable, 'Hyperlink', i)

                functions.append(FunctionDetails(department=fDepartment, function=fFunction, start=fStart,
                                                 end=fEnd, postalCode=fPostalCode, city=fCity, street=fStreet,
                                                 room=fRoom, building=fBuilding, phone=fPhone, fax=fFax,
                                                 mail=fMail, webpage=fWebpage))

        return DetailedPerson(firstname=firstname, lastname=lastname, academicTitle=academicTitle, gender=gender,
                              officeHour=officeHour, remarks=remarks, postalCode=postalCode, city=city,
                              street=street, office=office, building=building, phone=phone, fax=fax, mail=mail,
                              webpage=website, functions=functions)

    def parseHelpfulNumbers(self, helpfulNumbersJSON: str):
        """
        Parses a JSON containing helpful numbers.
        The JSON should have the form:
        { "language": language, "numbers": [ {"number": number, "link": link, "mail": mail, "name": name}, ... ] }
        @param helpfulNumbersJSON: str, JSON
        @return: a pair (language, list) where the list is a list of HelpfulNumber
        """
        helpfulNumbersData = json.loads(helpfulNumbersJSON)

        helpfulNumbers = []

        for helpfulNumber in helpfulNumbersData['numbers']:
            helpfulNumbers.append(HelpfulNumber(language=helpfulNumbersData['language'],
                                                number=helpfulNumber['number'], link=helpfulNumber['link'],
                                                mail=helpfulNumber['mail'], name=helpfulNumber['name']))

        return helpfulNumbersData['language'], helpfulNumbers


class UnspecificSearchQueryException(Exception):
    def __init__(self, query):
        self.query = query
