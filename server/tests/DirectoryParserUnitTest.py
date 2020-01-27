import unittest
from os.path import join
from source.parsers.DirectoryParser import DirectoryParser
from source.models.DirectoryModel import GeneralPerson, DetailedPerson

TEST_DIRECTORY = 'testdata/directory'
SEARCH_RESULT_FILE = 'searchResults.html'  # normal search results file
SEARCH_RESULT_EMPTY_FILE = 'searchResultsEmpty.html'  # search results with 0 results
SEARCH_RESULT_TOO_MANY_RESULTS_FILE = 'searchResultsTooManyResults.html'  # search results with more than 100 results
SEARCH_RESULT_TOO_FEW_CHARACTERS_FILE = 'searchResultsTooFewCharacters.html'  # search results with query with too few characters
DETAILS_FILE_1 = 'detailsNormal.html'  # normal details file
DETAILS_FILE_2 = 'detailsEmptyAddress.html'  # details file with empty address table
DETAILS_FILE_3 = 'detailsNoAddressTable.html'  # details file without address table

class DirectoryParserUnitTest(unittest.TestCase):

    def setUp(self) -> None:
        self.directoryParser = DirectoryParser()

        # read the testdata
        with open(join(TEST_DIRECTORY, SEARCH_RESULT_FILE), 'r') as f:
            self.searchResultHTML = f.read()

        with open(join(TEST_DIRECTORY, SEARCH_RESULT_EMPTY_FILE), 'r') as f:
            self.searchResultEmptyHTML = f.read()

        with open(join(TEST_DIRECTORY, SEARCH_RESULT_TOO_MANY_RESULTS_FILE), 'r') as f:
            self.searchResultTooManyResultsHTML = f.read()

        with open(join(TEST_DIRECTORY, SEARCH_RESULT_TOO_FEW_CHARACTERS_FILE), 'r') as f:
            self.searchResultTooFewCharactersHTML = f.read()

        with open(join(TEST_DIRECTORY, DETAILS_FILE_1), 'r') as f:
            self.detailsNormalHTML = f.read()

        with open(join(TEST_DIRECTORY, DETAILS_FILE_2), 'r') as f:
            self.detailsNoAddressHTML = f.read()

        with open(join(TEST_DIRECTORY, DETAILS_FILE_3), 'r') as f:
            self.detailsNoAddressTableHTML = f.read()

    def test_parseNormalSearchResults(self):
        """
        Tests if the parser correctly parses a normal search result html
        """
        searchResults, resultCount = self.directoryParser.parseWebpageForPIDs(self.searchResultHTML)

        # type
        self.assertIsInstance(searchResults, list,
                              "parseWebpageForPIDs returns type {}, expected list".format(type(searchResults)))
        for sr in searchResults:
            self.assertIsInstance(sr, GeneralPerson,
                                  "GeneralPerson of type {}, expected GeneralPerson".format(type(sr)))

        # result count
        self.assertEqual(4, len(searchResults), "Got {} search results, expected 4".format(len(searchResults)))
        self.assertEqual(4, resultCount, "Got {} search results, expected 4".format(resultCount))

        # search result content
        result1 = searchResults[0]
        result2 = searchResults[1]
        result3 = searchResults[2]
        result4 = searchResults[3]

        self.assertEqual("Christian Finkenzeller", result1.getName())
        self.assertEqual("", result1.getTitle())
        self.assertEqual(9823, result1.getPID())

        self.assertEqual("Julia Holzhäuser-Zeller", result2.getName())
        self.assertEqual("Dr.med.", result2.getTitle())
        self.assertEqual(19585, result2.getPID())

        self.assertEqual("Andreas Zeller", result3.getName())
        self.assertEqual("Univ.-Professor Dr.-Ing.", result3.getTitle())
        self.assertEqual(2307, result3.getPID())

        self.assertEqual("Tanja Zeller", result4.getName())
        self.assertEqual("", result4.getTitle())
        self.assertEqual(13107, result4.getPID())

    def test_parseEmptySearchResults(self):
        """
        Tests the parser on an empty search results page
        """
        searchResults, resultCount = self.directoryParser.parseWebpageForPIDs(self.searchResultEmptyHTML)

        # type
        self.assertIsInstance(searchResults, list,
                              "parseWebpageForPIDs returns type {}, expected list".format(type(searchResults)))

        # result count
        self.assertEqual(0, len(searchResults), "Got {} search results, expected 0".format(len(searchResults)))
        self.assertEqual(0, resultCount, "Got {} search results, expected 0".format(resultCount))

    def test_parseSearchResultsTooManyResults(self):
        """
        Tests the parser on a search results page where there are too many results
        """
        searchResults, resultCount = self.directoryParser.parseWebpageForPIDs(self.searchResultTooManyResultsHTML)

        # type
        self.assertIsNone(searchResults, "Expected persewWebpageForPIDs to return None")

        # count
        self.assertEqual(0, resultCount, "Got {} search results, expected 0".format(resultCount))

    def test_parseSearchResultsTooFewCharacters(self):
        """
        Tests the parser on a search results page where the user entered too few characters to get results
        """
        searchResults, resultCount = self.directoryParser.parseWebpageForPIDs(self.searchResultTooFewCharactersHTML)

        # type
        self.assertIsNone(searchResults, "Expected perseWebpageForPIDs to return None")

        # count
        self.assertEqual(0, resultCount, "Got {} search results, expected 0".format(resultCount))

    def test_parseNormalDetails(self):
        """
        Tests the parser on a normal details page
        """
        details = self.directoryParser.parsePersonDetail(self.detailsNormalHTML)

        # type
        self.assertIsInstance(details, DetailedPerson,
                              "Got detailed person of type {}, expected DetailedPerson".format(type(details)))

        # contents
        self.assertEqual("Andreas", details.getFirstname())
        self.assertEqual("Zeller", details.getLastname())
        self.assertEqual("Univ.-Professor Dr.-Ing.", details.getAcademicTitle())
        self.assertEqual("männlich", details.getGender('de'))
        self.assertEqual("", details.getOfficeHour())
        self.assertEqual("", details.getRemark())
        self.assertEqual("2.07", details.getOffice())
        self.assertEqual("Gebäude E9 1", details.getBuilding())
        self.assertEqual("Stuhlsatzenhaus 5", details.getStreet())
        self.assertEqual("66123", details.getPostalCode())
        self.assertEqual("Saarbrücken", details.getCity())
        self.assertEqual("+49 (0)681 / 302-70971", details.getPhone())
        self.assertEqual("+49 (0)681 / 302-70972", details.getFax())
        self.assertEqual("zeller@cispa.saarland", details.getMail())
        self.assertEqual("https://cispa.saarland/people/zeller/", details.getWebpage())

    def test_parseDetailsNoAddress(self):
        """
        Tests the parser on a details page with an empty address table
        """
        details = self.directoryParser.parsePersonDetail(self.detailsNoAddressHTML)

        # type
        self.assertIsInstance(details, DetailedPerson,
                              "Got detailed person of type {}, expected DetailedPerson".format(type(details)))

        # contents
        self.assertEqual("Julia", details.getFirstname())
        self.assertEqual("Holzhäuser-Zeller", details.getLastname())
        self.assertEqual("Dr.med.", details.getAcademicTitle())
        self.assertEqual("weiblich", details.getGender('de'))
        self.assertEqual("", details.getOfficeHour())
        self.assertEqual("", details.getRemark())
        self.assertEqual("", details.getOffice())
        self.assertEqual("", details.getBuilding())
        self.assertEqual("", details.getStreet())
        self.assertEqual("", details.getPostalCode())
        self.assertEqual("", details.getCity())
        self.assertEqual("", details.getPhone())
        self.assertEqual("", details.getFax())
        self.assertEqual("", details.getMail())
        self.assertEqual("", details.getWebpage())

    def test_parseDetailsNoAddressTable(self):
        """
        Tests the parser on a details page without an address table
        """
        details = self.directoryParser.parsePersonDetail(self.detailsNoAddressTableHTML)

        # type
        self.assertIsInstance(details, DetailedPerson,
                              "Got detailed person of type {}, expected DetailedPerson".format(type(details)))

        # contents
        self.assertEqual("Tanja", details.getFirstname())
        self.assertEqual("Zeller", details.getLastname())
        self.assertEqual("", details.getAcademicTitle())
        self.assertEqual("weiblich", details.getGender('de'))
        self.assertEqual("", details.getOfficeHour())
        self.assertEqual("", details.getRemark())
        self.assertEqual("", details.getOffice())
        self.assertEqual("", details.getBuilding())
        self.assertEqual("", details.getStreet())
        self.assertEqual("", details.getPostalCode())
        self.assertEqual("", details.getCity())
        self.assertEqual("", details.getPhone())
        self.assertEqual("", details.getFax())
        self.assertEqual("", details.getMail())
        self.assertEqual("", details.getWebpage())

if __name__ == '__main__':
    unittest.main()
