import unittest
from source.models.MensaModel import Notice, Location, Counter
from source.models.NewsModel import NewsModel
from source.models.EventModel import EventModel
from source.models.DirectoryModel import DetailedPerson, GeneralPerson
from datetime import datetime


class ModelsUnitTest(unittest.TestCase):
    def test_Notice(self):
        n1 = Notice('abc', 'Notice1', True, False)
        n2 = Notice('abc', 'Notice2', False, True)
        n3 = Notice('cde', 'Notice2', False, True)
        self.assertTrue(n1 == n2)
        self.assertEqual(hash(n1), hash(n2))
        self.assertFalse(n2 == n3)
        self.assertFalse(n1 == n3)

    def test_Location(self):
        l1 = Location('sb', 'SB', 'description')
        l2 = Location('hom', 'HOM', 'description')
        l3 = Location('sb', 'HOM', 'description')
        self.assertTrue(l1 == l3)
        self.assertEqual(hash(l1), hash(l3))
        self.assertFalse(l2 == l3)
        self.assertFalse(l1 == l2)

    def test_Counter(self):
        c1 = Counter('A', 'Komplettmenü', 'Fleisch', [])
        c2 = Counter('B', 'Komplettmenü', 'Fleisch', [])
        c3 = Counter('A', 'Free Flow', 'Free', [])
        self.assertEqual(c1, c3)
        self.assertEqual(hash(c1), hash(c3))
        self.assertNotEqual(c1, c2)
        self.assertNotEqual(c3, c2)

    def test_NewsModel(self):
        n1 = NewsModel('title', datetime.today().date(), 123456789, 'link', [], 'description', 'content', 'imageLink')
        n2 = NewsModel('title', datetime.today().date(), 123, 'link', [], 'description', 'content', 'imageLink')
        n3 = NewsModel('title2', datetime.today().date(), 123, 'link', [], 'description', 'content', 'imageLink')
        self.assertEqual(n1, n2)
        self.assertEqual(hash(n1), hash(n2))
        self.assertNotEqual(n1, n3)
        self.assertNotEqual(n2, n3)

    def test_EventModel(self):
        e1 = EventModel('title', datetime.today().date(), datetime.today().date(), 123, 'link', [], 'description', '')
        e2 = EventModel('title', datetime.today().date(), datetime.today().date(), 321, 'link', [], 'description', '')
        e3 = EventModel('title2', datetime.today().date(), datetime.today().date(), 123, 'link', [], 'description', '')
        self.assertTrue(e1 == e2)
        self.assertEqual(hash(e1), hash(e2))
        self.assertNotEqual(e1, e3)
        self.assertNotEqual(e2, e3)


if __name__ == '__main__':
    unittest.main()
