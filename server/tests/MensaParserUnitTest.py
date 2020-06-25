import unittest
from source.parsers.MensaParser import MensaParser
from source.models.MensaModel import *
from source.views.MensaView import MensaView
import json

MENSA_BASE_DATA = '{"locations":{"sb":{"displayName":"Mensa / Mensacafe Saarbrücken","description":"Die Mensa auf dem Campus Saarbrücken befindet sich in Gebäude D 4.1. In der denkmalgeschützten, künstlerisch sehr interessanten Mensa bieten wir Ihnen täglich die Möglichkeit, aus bis zu dreizehen verschiedenen Essen auszuwählen."},"hom":{"displayName":"Mensa Homburg","description":"Die Mensa in Homburg und die Cafete befinden sich auf dem Gelände des Universitätsklinikums des Saarlandes, Gebäude 74.In der Mensa können unsere Gäste mittags zwischen dem Komplettmenü, dem vegetarischen Menü, dem Wahlessen und dem Tellergericht wählen."},"musiksb":{"displayName":"Cafeteria Hochschule für Musik Saar","description":"Die Cafeteria befindet sich im Gebäude der Hochschule für Musik und Theater. Hier bieten wir nur während der Vorlesungszeit täglich warme Gerichte, Kuchen, Snacks und Getränke an."},"htwgtb":{"displayName":"Cafeteria HTW Göttelborn","description":"Die Cafeteria befindet sich im Gebäude der HTW in Göttelborn. Hier bieten wir durchgehend warme Gerichte, Kuchen, Snacks und Getränke an, sowie über die Mittagszeit ein Komplettmenü und ein vegetarisches Menü."},"mensagarten":{"displayName":"Mensagarten","description":"Der Mensagarten befindet sich auf der Wiese hinter Gebäude A1.7 (ehemaliger Botanischer Garten). Wir bieten dort von montags bis freitags von 11:00 - 15:00 Uhr an einem lauschigen Platz auf dem Campus täglich wechselnde Pizza- und Pastagerichte an."},"htwcas":{"displayName":"Mensa HTW Saar CAS","description":"Die neue Mensa der htw saar befindet sich  im Gebäude 10 auf dem Campus Alt-Saarbrücken. Dort können unsere Gäste mittags neben dem Komplettmenü und dem vegetarischen Menü auch zwischen Angeboten aus der Aktions- und einer Selbstbedienungstheke wählen. Eine Salatbar steht ebenfalls zur Verfügung. Außerdem bieten wir auch belegte Brötchen, Snacks und Backwaren an."},"htwcrb":{"displayName":"Mensa HTW Saar CRB","description":"Die Mensa am Campus Rotenbühl finden Sie im Gebäude B im Untergeschoss. In den hell und freundlich eingerichteten Räumen gibt es täglich zwei Gerichte zur Auswahl. Besonders schön ist die Außenterrasse, die ganz im Grünen gelegen, zum Entspannen einlädt."}},"priceTiers":{"s":{"displayName":"Studenten"},"m":{"displayName":"Bedienstete"},"g":{"displayName":"Gäste"}},"knownMeals":{"gebfl":{"displayName":"Gebackener Fleischkäse"}},"notices":{"fs":{"displayName":"Farbstoff","isAllergen":false,"isNegated":false},"ks":{"displayName":"Konservierungsstoff","isAllergen":false,"isNegated":false},"ao":{"displayName":"Antioxidationsmittel","isAllergen":false,"isNegated":false},"gv":{"displayName":"Geschmacksverstärker","isAllergen":false,"isNegated":false},"su":{"displayName":"geschwefelt","isAllergen":false,"isNegated":false},"bl":{"displayName":"geschwärzt","isAllergen":false,"isNegated":false},"gw":{"displayName":"gewachst","isAllergen":false,"isNegated":false},"ph":{"displayName":"Phosphat","isAllergen":false,"isNegated":false},"sm":{"displayName":"Süßungsmittel","isAllergen":false,"isNegated":false},"pa":{"displayName":"Paranüsse","isAllergen":true,"isNegated":false},"me":{"displayName":"Milcheiweiß","isAllergen":false,"isNegated":false},"gf":{"displayName":"Geflügel","isAllergen":false,"isNegated":false},"swf":{"displayName":"Schweinefleisch","isAllergen":false,"isNegated":false},"al":{"displayName":"Alkohol","isAllergen":false,"isNegated":false},"nu":{"displayName":"Schalenfrüchte (Nüsse)","isAllergen":true,"isNegated":false},"nsf":{"displayName":"ohne Schweinefleisch","isAllergen":false,"isNegated":true},"kn":{"displayName":"Knoblauch","isAllergen":false,"isNegated":false},"ve":{"displayName":"vegetarisch","isAllergen":false,"isNegated":false},"bio":{"displayName":"biologisches Esses","isAllergen":false,"isNegated":false},"ba":{"displayName":"Backtriebmittel","isAllergen":false,"isNegated":false},"nla":{"displayName":"laktosefrei","isAllergen":false,"isNegated":false},"vn":{"displayName":"vegan","isAllergen":false,"isNegated":false},"fnf":{"displayName":"Fisch aus nachhaltigem Fang","isAllergen":false,"isNegated":false},"azf":{"displayName":"aus zum Teil fein zerkleinertem Fleisch","isAllergen":false,"isNegated":false},"gl":{"displayName":"Gluten","isAllergen":true,"isNegated":false},"kr":{"displayName":"Krebstiere, Krusten- und Schalentiere","isAllergen":true,"isNegated":false},"ei":{"displayName":"Ei","isAllergen":true,"isNegated":false},"fi":{"displayName":"Fisch","isAllergen":true,"isNegated":false},"en":{"displayName":"Erdnüsse","isAllergen":true,"isNegated":false},"so":{"displayName":"Soja","isAllergen":true,"isNegated":false},"la":{"displayName":"Milch und Laktose","isAllergen":true,"isNegated":false},"lab":{"displayName":"mit tierischem LAB","isAllergen":true,"isNegated":false},"sl":{"displayName":"Sellerie","isAllergen":true,"isNegated":false},"snf":{"displayName":"Senf","isAllergen":true,"isNegated":false},"se":{"displayName":"Sesamsamen","isAllergen":true,"isNegated":false},"sw":{"displayName":"Schwefeldioxid / Sulfite","isAllergen":true,"isNegated":false},"lu":{"displayName":"Lupinen","isAllergen":true,"isNegated":false},"wt":{"displayName":"Weichtiere","isAllergen":true,"isNegated":false},"we":{"displayName":"Weizen","isAllergen":true,"isNegated":false},"ro":{"displayName":"Roggen","isAllergen":true,"isNegated":false},"ge":{"displayName":"Gerste","isAllergen":true,"isNegated":false},"ha":{"displayName":"Hafer","isAllergen":true,"isNegated":false},"di":{"displayName":"Dinkel","isAllergen":true,"isNegated":false},"ka":{"displayName":"Kamut","isAllergen":true,"isNegated":false},"ma":{"displayName":"Mandeln","isAllergen":true,"isNegated":false},"has":{"displayName":"Haselnüsse","isAllergen":true,"isNegated":false},"wa":{"displayName":"Walnüsse","isAllergen":true,"isNegated":false},"kas":{"displayName":"Kaschunüsse","isAllergen":true,"isNegated":false},"pe":{"displayName":"Pecannüsse","isAllergen":true,"isNegated":false},"pi":{"displayName":"Pistazien","isAllergen":true,"isNegated":false},"mq":{"displayName":"Macadamia-oder-Queenslandnüsse","isAllergen":true,"isNegated":false}}}'
MENSA_MENU_SB = '{"days":[{"date":"2019-12-16T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-16T10:30:00.000Z","end":"2019-12-17T13:15:00.000Z"},"meals":[{"name":"Ungarisches Gulasch","notices":[],"components":[{"name":"Makkaroni (aus biologischem Anbau)","notices":["we"]},{"name":"Krautsalat Maryland","notices":["fs","ei","la"]},{"name":"Spargelcremesuppe","notices":["ve","la","sl"]},{"name":"Aprikosenquark","notices":["la"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-16T10:30:00.000Z","end":"2019-12-17T13:15:00.000Z"},"meals":[{"name":"Kartoffelgratin","notices":["ks","lab","ei","la"],"components":[{"name":"Lollo Rosso","notices":[]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Vanillepudding","notices":["la"]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-16T10:30:00.000Z","end":"2019-12-17T12:45:00.000Z"},"meals":[{"name":"Tilapiafilet, Balsamicolinsen, Meerrettichstampfkartoffeln","notices":["fnf","ei","fi","la","snf","sw","we"],"components":[],"category":"mensaVital"},{"name":"Spaghetti mit Pinien-Knoblauch-Soße","notices":["kn","vn","so","we"],"components":[],"category":"Vegan"},{"name":"Paniertes Schnitzel vom Schwein","notices":["fs","ks","swf","we"],"components":[{"name":"Waldpilzsoße","notices":["al","kn","la","snf","sw"]},{"name":"Geriebener Käse","notices":["la"]}]},{"name":"Nudelauflauf  Havanna","notices":["kn","ei","la","we"],"components":[],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"},{"name":"Salatbuffet","notices":[],"components":[{"name":"Tomatensalat","notices":[]},{"name":"Weisskraut","notices":[]},{"name":"Gurken","notices":[]},{"name":"Zwiebel Ringe","notices":[]},{"name":"Karotten","notices":[]},{"name":"Gemischter Paprika","notices":[]},{"name":"Mais","notices":[]},{"name":"Peperoni","notices":[]},{"name":"Endiviensalat","notices":[]},{"name":"Lollo Rosso","notices":[]},{"name":"Radicchio","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]}],"prices":{"s":"3,06","m":"3,68","g":"4,22"}}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-16T10:30:00.000Z","end":"2019-12-17T13:30:00.000Z"},"meals":[{"name":"Hot Dog mit Röstzwiebeln","notices":["ks","ao","swf","al","vn","snf","we","ge"],"components":[]},{"name":"Hot Dog vegetarisch mit Röstzwiebeln","notices":["fs","al","ve","vn","ei","snf","we","ge"],"components":[]},{"name":"Brüsseler Waffel mit Sahne und heißen Kirschen","notices":["ei","la","we"],"components":[]}]},{"id":"mensacafe-abend","displayName":"Mensacafé (Abendessen)","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T14:30:00.000Z","end":"1970-01-01T19:00:00.000Z"},"color":{"r":135,"g":10,"b":194},"feedback":{"start":"2019-12-16T13:30:00.000Z","end":"2019-12-17T18:00:00.000Z"},"meals":[{"name":"Bunter Blattsalat","notices":[],"components":[{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]}],"prices":{"s":"2,60","m":"3,22","g":"3,76"}},{"name":"Fish and chips","notices":["la","we"],"components":[{"name":"Remouladensoße","notices":["fs","ei","la","snf"]}]},{"name":"Kartoffelgnocchi gefüllt mit Frischkäse","notices":["ks","ao","la","we"],"components":[{"name":"Karotten in Käsebechamelsoße","notices":["ve","la"]},{"name":"Geriebener Käse","notices":["la"]}]}]}]},{"date":"2019-12-17T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-17T10:30:00.000Z","end":"2019-12-18T13:15:00.000Z"},"meals":[{"name":"Penne Rigate (aus biologischem Anbau)","notices":["we"],"components":[{"name":"Bolognese Soße","notices":["nsf","kn","sl"]},{"name":"Geriebener Käse","notices":["la"]},{"name":"Karottensalat","notices":["fs","ei","la","snf"]},{"name":"Frühlingssuppe","notices":["sl"]},{"name":"Vanillepudding","notices":["la","we"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-17T10:30:00.000Z","end":"2019-12-18T13:15:00.000Z"},"meals":[{"name":"Frühlingsrolle vegetarisch","notices":["ve","ba","ei","so","la","sl","we"],"components":[{"name":"Soße süß-sauer","notices":["so","sl","snf","we"]},{"name":"Tomatenreis","notices":[]},{"name":"Bunt gemischter Blattsalat","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Fruchtjoghurt","notices":["la"]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-17T10:30:00.000Z","end":"2019-12-18T12:45:00.000Z"},"meals":[{"name":"Marinierte Hähnchenkeule auf Gemüserisotto","notices":["gf","so","we"],"components":[],"category":"mensaVital"},{"name":"Hausgemachte Kartoffelsuppe mit fritierten Tofustreifen","notices":["ao","vn","so","sl","we"],"components":[{"name":"Brötchen","notices":["la","we"]}],"category":"Vegan"},{"name":"Gegrilltes Seelachsfilet","notices":["fi"],"components":[{"name":"Zitronen-Kräutersoße","notices":["la"]},{"name":"Petersilienkartoffel","notices":[]},{"name":"Reis Fair Trade","notices":[]}]},{"name":"Eblypfanne Mediterrané","notices":["vn","sl","we"],"components":[],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"},{"name":"Salatbuffet","notices":[],"components":[{"name":"Tomatensalat","notices":[]},{"name":"Weisskraut","notices":[]},{"name":"Gurken","notices":[]},{"name":"Zwiebel Ringe","notices":[]},{"name":"Karotten","notices":[]},{"name":"Gemischter Paprika","notices":[]},{"name":"Mais","notices":[]},{"name":"Peperoni","notices":[]},{"name":"Lollo Bianco","notices":[]},{"name":"Kopfsalat","notices":[]},{"name":"Radicchio","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]}],"prices":{"s":"3,06","m":"3,68","g":"4,22"}}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-17T10:30:00.000Z","end":"2019-12-18T13:30:00.000Z"},"meals":[{"name":"Pizza Speziale mit Salami und Schinken","notices":["fs","ks","ao","swf","la","snf","we"],"components":[]},{"name":"Pizza mit frischen Champignons","notices":["la","we"],"components":[]}]},{"id":"mensacafe-abend","displayName":"Mensacafé (Abendessen)","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T14:30:00.000Z","end":"1970-01-01T19:00:00.000Z"},"color":{"r":135,"g":10,"b":194},"feedback":{"start":"2019-12-17T13:30:00.000Z","end":"2019-12-18T18:00:00.000Z"},"meals":[{"name":"Bunter Blattsalat","notices":[],"components":[{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]}],"prices":{"s":"2,60","m":"3,22","g":"3,76"}},{"name":"Hähnchenstreifen in Cornflakespanade","notices":["gf","we","ge"],"components":[{"name":"Barbecuesoße","notices":["sl"]},{"name":"Beilage nach Wahl","notices":["we"]}]},{"name":"Nudelauflauf don petro","notices":["kn","ei","la","we"],"components":[{"name":"Lollo Rosso","notices":[]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]}]}]}]},{"date":"2019-12-18T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-18T10:30:00.000Z","end":"2019-12-19T13:15:00.000Z"},"meals":[{"name":"Paniertes Schnitzel vom Schwein","notices":["swf","we"],"components":[{"name":"Soße Balkan Art","notices":[]},{"name":"Tomatenreis","notices":[]},{"name":"Bunter Rohkostsalat","notices":["fs","ei","la"]},{"name":"Eiermuschelsuppe","notices":["ve","sl"]},{"name":"Schokoladenpudding","notices":["la","we"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-18T10:30:00.000Z","end":"2019-12-19T13:15:00.000Z"},"meals":[{"name":"Pommes Wedges","notices":["we"],"components":[{"name":"Chili-Kräuterdip","notices":["so","la","snf","we"]},{"name":"Lollo Rosso","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Obst","notices":[]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-18T10:30:00.000Z","end":"2019-12-19T12:45:00.000Z"},"meals":[{"name":"Putengeschnetzeltes Thailändische Art mit Duftreis","notices":["gf","la","we"],"components":[],"category":"mensaVital"},{"name":"Burrito mit Grünkernfüllung","notices":["kn","vn","we"],"components":[],"category":"Vegan"},{"name":"ZiS: Spezialitätentag","notices":[],"components":[]},{"name":"Nudelsalat","notices":["fs","kn","ei","la","snf","we"],"components":[{"name":"Bratwurst","notices":["ao","gv","ph","me","swf"]}],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"},{"name":"Salatbuffet","notices":[],"components":[{"name":"Tomatensalat","notices":[]},{"name":"Weisskraut","notices":[]},{"name":"Gurken","notices":[]},{"name":"Zwiebel Ringe","notices":[]},{"name":"Karotten","notices":[]},{"name":"Gemischter Paprika","notices":[]},{"name":"Mais","notices":[]},{"name":"Peperoni","notices":[]},{"name":"Lollo Bianco","notices":[]},{"name":"Eichblattsalat","notices":[]},{"name":"Radicchio","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]}],"prices":{"s":"3,06","m":"3,68","g":"4,22"}}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-18T10:30:00.000Z","end":"2019-12-19T13:30:00.000Z"},"meals":[{"name":"Hausgemachte Erbsensuppe","notices":["sl","we"],"components":[{"name":"Wiener Würstchen","notices":["ao","gv","ph","me","swf","snf"]},{"name":"Brötchen","notices":["la","we"]}]},{"name":"Hausgemachte Erbsensuppe","notices":["sl","we"],"components":[{"name":"Brötchen","notices":["la","we"]}]},{"name":"Brüsseler Waffel mit Sahne und heißen Kirschen","notices":["ei","so","we"],"components":[]}]},{"id":"mensacafe-abend","displayName":"Mensacafé (Abendessen)","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T14:30:00.000Z","end":"1970-01-01T19:00:00.000Z"},"color":{"r":135,"g":10,"b":194},"feedback":{"start":"2019-12-18T13:30:00.000Z","end":"2019-12-19T18:00:00.000Z"},"meals":[{"name":"Bunter Blattsalat","notices":[],"components":[{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]}],"prices":{"s":"2,60","m":"3,22","g":"3,76"}},{"name":"Gebackenes Hähnchenbrustfilet","notices":["gf","nsf","we"],"components":[{"name":"Soße süß-sauer","notices":["so","sl","snf","we"]},{"name":"Beilage nach Wahl","notices":["we"]}]},{"name":"Grünkohl-Hanf-Bratling","notices":["vn"],"components":[{"name":"Braune Soße","notices":["vn"]},{"name":"Beilage nach Wahl","notices":["we"]}],"category":"Vegan"}]}]},{"date":"2019-12-19T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-19T10:30:00.000Z","end":"2019-12-20T13:15:00.000Z"},"meals":[{"name":"Hausgemachte Frikadelle","notices":["swf","ei","snf","we"],"components":[{"name":"Rahmsoße","notices":["la"]},{"name":"Pommes Frites","notices":[]},{"name":"Pusztasalat","notices":["fs","ei","la","snf"]},{"name":"Gemüsecremesuppe","notices":["kn","la"]},{"name":"Milchreis mit Zimt und Zucker","notices":["la"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:15:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-19T10:30:00.000Z","end":"2019-12-20T13:15:00.000Z"},"meals":[{"name":"Indisches Linsencurry","notices":["kn","la","sl","snf"],"components":[{"name":"Reis (aus biologischem Anbau)","notices":[]},{"name":"Lollo Rosso","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Fruchtcocktail","notices":["fs"]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-19T10:30:00.000Z","end":"2019-12-20T12:45:00.000Z"},"meals":[{"name":"mensaVital:Gedünstetes Kabeljaufilet(nachhaltiger Fischfang) auf Blattspinat mit Tomatentagliatelle","notices":["kn","fnf","ei","fi","la","we"],"components":[]},{"name":"Quinoa-Erbsen- Bratling","notices":["vn","sl"],"components":[{"name":"Knoblauch-Kräuter-Dip","notices":["kn","vn","so"]},{"name":"Steakhouse Pommes","notices":[]}],"category":"Vegan"},{"name":"Kürbis-Hackfleisch-Reisgericht","notices":["swf","kn","ma"],"components":[],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"},{"name":"Salatbuffet","notices":[],"components":[{"name":"Tomatensalat","notices":[]},{"name":"Weisskraut","notices":[]},{"name":"Gurken","notices":[]},{"name":"Zwiebel Ringe","notices":[]},{"name":"Karotten","notices":[]},{"name":"Gemischter Paprika","notices":[]},{"name":"Mais","notices":[]},{"name":"Peperoni","notices":[]},{"name":"Romasalat","notices":[]},{"name":"Lollo Bianco","notices":[]},{"name":"Radicchio","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]}],"prices":{"s":"3,06","m":"3,68","g":"4,22"}}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-19T10:30:00.000Z","end":"2019-12-20T13:30:00.000Z"},"meals":[{"name":"Crêpes mit Zimt und Zucker oder Nusscremefüllung","notices":["nla","ei","we"],"components":[]}]},{"id":"mensacafe-abend","displayName":"Mensacafé (Abendessen)","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T14:30:00.000Z","end":"1970-01-01T19:00:00.000Z"},"color":{"r":135,"g":10,"b":194},"feedback":{"start":"2019-12-19T13:30:00.000Z","end":"2019-12-20T18:00:00.000Z"},"meals":[{"name":"Bunter Blattsalat","notices":[],"components":[{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]}],"prices":{"s":"2,60","m":"3,22","g":"3,76"}},{"name":"Schweinegulasch Italienische Art","notices":["swf","al","kn","sw"],"components":[{"name":"Reis (aus biologischem Anbau)","notices":[]}]},{"name":"Rigatoni (biologischer Anbau)","notices":["ve","bio","we"],"components":[{"name":"Grünkernbolognaise","notices":["kn","sl","di"]},{"name":"Geriebener Käse","notices":["la"]}]}]}]},{"date":"2019-12-20T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:00:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:00:00.000Z"},"meals":[{"name":"Hähnchen-Cordon-Bleu (mit Putenschinken)","notices":["ks","ao","su","ph","me","gf","la","we"],"components":[{"name":"Ketchup","notices":[]},{"name":"Pommes Frites","notices":[]},{"name":"Lollo Rosso","notices":[]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Pfirsichkompott","notices":[]},{"name":"Lauchcremesuppe","notices":["ve"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:00:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:00:00.000Z"},"meals":[{"name":"Chili sin carne","notices":["kn","ve","vn"],"components":[{"name":"Nachos","notices":["fs","gv"]},{"name":"Lollo Rosso","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Milchreis mit Zimt und Zucker","notices":["la"]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T12:45:00.000Z"},"meals":[{"name":"Chili-Pasta mit Knoblauch und Hartkäse","notices":["ks","kn","lab","ei","la","we","pi"],"components":[],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:30:00.000Z"},"meals":[{"name":"Flammkuchen Saarländische Art mit Lyoner und Kartoffelwürfel","notices":["swf","la","snf","we"],"components":[]},{"name":"Flammkuchen mit buntem Gemüse","notices":["la","we"],"components":[]}]}]}]}'
MENSA_MENU_BEFORE_CHRISTMAS = '{"days":[{"date":"2019-12-20T00:00:00.000Z","isPast":false,"counters":[{"id":"komplett","displayName":"Komplettmenü","description":"Aufgang A und B (links)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:00:00.000Z"},"color":{"r":217,"g":38,"b":26},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:00:00.000Z"},"meals":[{"name":"Hähnchen-Cordon-Bleu (mit Putenschinken)","notices":["ks","ao","su","ph","me","gf","la","we"],"components":[{"name":"Ketchup","notices":[]},{"name":"Pommes Frites","notices":[]},{"name":"Karottensalat","notices":["fs","ei","la","snf"]},{"name":"Dessert","notices":["la","has"]},{"name":"Lauchcremesuppe","notices":["ve","la","snf","so","se","sl"]}],"prices":{"s":"3,10","m":"5,25","g":"7,30"}}]},{"id":"vegetarisch","displayName":"Vegetarisches Menü","description":"Aufgang B (rechts)","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:00:00.000Z"},"color":{"r":21,"g":135,"b":207},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:00:00.000Z"},"meals":[{"name":"Chili sin carne","notices":["kn","ve","vn"],"components":[{"name":"Nachos","notices":["fs","gv"]},{"name":"Lollo Rosso","notices":[]},{"name":"Klare Salatsoße","notices":["snf"]},{"name":"Weiße Salatsoße","notices":["fs","ei","la","snf"]},{"name":"Dessert","notices":["la","has"]}],"prices":{"s":"2,45","m":"4,30","g":"5,95"}}]},{"id":"freeflow","displayName":"Free Flow","description":"Aufgang C","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T13:45:00.000Z"},"color":{"r":245,"g":204,"b":43},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T12:45:00.000Z"},"meals":[{"name":"Chili-Pasta mit Knoblauch und Hartkäse(Ohne Hartkäse VEGAN)","notices":["ks","kn","lab","ei","la","we","pi"],"components":[],"prices":{"s":"1,90","m":"2,95","g":"3,75"},"category":"Tellergericht"}]},{"id":"mensacafe","displayName":"Mensacafé","description":"Erdgeschoss","openingHours":{"start":"1970-01-01T11:30:00.000Z","end":"1970-01-01T14:30:00.000Z"},"color":{"r":16,"g":107,"b":10},"feedback":{"start":"2019-12-20T10:30:00.000Z","end":"2019-12-21T13:30:00.000Z"},"meals":[{"name":"Flammkuchen Saarländische Art mit Lyoner und Kartoffelwürfel","notices":["swf","la","snf","we"],"components":[],"prices":{"s":"3,60","m":"4,22","g":"4,76"}},{"name":"Flammkuchen mit Gemüse und Schafskäse","notices":["la","we"],"components":[],"prices":{"s":"3,60","m":"4,22","g":"4,76"}},{"name":"Apfelstrudel","notices":["ei","we"],"components":[],"prices":{"s":"1,80","m":"1,80","g":"2,25"}}]},{"id":"info","displayName":"Information","description":"","color":{"r":0,"g":0,"b":0},"meals":[{"name":"Info:","notices":[],"components":[{"name":"Freitag den","notices":[]},{"name":"20.12.2019 ist die Essensausgabe Komplettmenü und Vegetarisches Menü bis 14:00 Uhr geöffnet. Wir wünschen Ihnen frohe Weihnachten und einen guten Rutsch ins neue Jahr. Ihr Mensa-Team","notices":[]}]}]}]}]}'

class MensaParserUnitTest(unittest.TestCase):
    def setUp(self) -> None:
        mensaModel = MensaModel()
        self.mensaParser = MensaParser(mensaModel)
        self.baseData = self.mensaParser.parseBaseData(MENSA_BASE_DATA)
        self.mensaView = MensaView()

    def test_parseBaseDataKeys(self):
        self.assertTrue("notices" in self.baseData)
        self.assertTrue("locations" in self.baseData)
        self.assertTrue("knownMeals" in self.baseData)
        self.assertTrue("priceTiers" in self.baseData)
        self.assertTrue("globalMessage" in self.baseData)

    def test_parseBaseDataOptionals_emptyKnownMeals(self):
        baseData = {
            "notices": {"dN": {"displayName": "this is a display name", "isAllergen": True, "isNegated": True}},
            "locations": {"sb": {"displayName": "Name1", "description": "best location"}},
            "knownMeals": {},
            "priceTiers": {"s": {"displayName": "student"}},
            "globalMessage": {"title": "Title", "text": "global Message"}
        }
        baseDataJSON = json.dumps(baseData)
        parsedBaseData = self.mensaParser.parseBaseData(baseDataJSON)

    def test_parseBaseDataOptionals_emptyPriceTiers(self):
        baseData = {
            "notices": {"dN": {"displayName": "this is a display name", "isAllergen": True, "isNegated": True}},
            "locations": {"sb": {"displayName": "Name1", "description": "best location"}},
            "knownMeals": {"Gebackener Fleischkäse": {"displayName": "Gebackener Fleischkäs",
                                                      "lastOffered": str(datetime.today().date())}},
            "priceTiers": {},
            "globalMessage": {"title": "Title", "text": "global Message"}
        }
        baseDataJSON = json.dumps(baseData)
        parsedBaseData = self.mensaParser.parseBaseData(baseDataJSON)

    def test_parseBaseDataOptionals_emptyLocations(self):
        baseData = {
            "notices": {"dN": {"displayName": "this is a display name", "isAllergen": True, "isNegated": True}},
            "locations": {},
            "knownMeals": {"Gebackener Fleischkäse": {"displayName": "Gebackener Fleischkäs",
                                                      "lastOffered": str(datetime.today())}},
            "priceTiers": {"s": {"displayName": "student"}},
            "globalMessage": {"title": "Title", "text": "global Message"}
        }
        baseDataJSON = json.dumps(baseData)
        parsedBaseData = self.mensaParser.parseBaseData(baseDataJSON)

    def test_parseMenuDataAllOptionals(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noOpeningHours(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noColor(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noFeedback(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noKnownMealID(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noPrices(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "pricingNotice": "This is a price",
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noPricingNotice(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "category": "Fleisch"
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataAllOptionals_noCategory(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                      "start": str(datetime.now()),
                      "end": str(datetime.now())
                      },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                        }
                    ]
                }]
            }]
        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)

    def test_parseMenuDataSB(self):
        servingDayList = self.mensaParser.parseMenuData(MENSA_MENU_SB)
        for servingDay in servingDayList:
            self.assertTrue(isinstance(servingDay, ServingDay))
        for servingDay in servingDayList:
            counters = servingDay.getCounters()
            for counter in counters:
                self.assertTrue(isinstance(counter, Counter))
        servingDay = servingDayList[0]
        counters = servingDay.getCounters()
        for counter in counters:
            if counter.getID() == "komplett":
                self.assertTrue(counter.getName() == "Komplettmenü")
                self.assertTrue(counter.getDescription() == "Aufgang A und B (links)")
                self.assertTrue(len(counter.getMeals()) == 1)
                meal = counter.getMeals()[0]
                self.assertTrue(isinstance(meal, Meal))
                self.assertTrue(meal.getName() == "Ungarisches Gulasch")
                components = meal.getComponents()
                self.assertTrue(len(components) == 4)
                for component in components:
                    self.assertTrue(isinstance(component, Component))
                    if component.getName() == "Makkaroni (aus biologischem Anbau)":
                        self.assertTrue(component.getNotices()[0].getID() == "we")
                    if component.getName() == "Krautsalat Maryland":
                        self.assertTrue(len(component.getNotices()) == 3)

    def test_menuWithInfoEntry(self):
        servingDays = self.mensaParser.parseMenuData(MENSA_MENU_BEFORE_CHRISTMAS)
        counters = servingDays[0].getCounters()
        servingDayJSON = self.mensaView.servingDayToJSON(servingDays[0], 'de')
        for counter in counters:
            for meal in counter.getMeals():
                mealJSON = self.mensaView.mealGeneralToJSON(meal, counter)
                

    def test_dictDataToList(self):
        testDict = {'id1': {'infoID1': 'info1', 'infoID2': 'info2'}, 'id2': {}}
        testList = self.mensaParser.dictDataToList(testDict, "name")
        self.assertTrue(len(testList) == 2)
        self.assertTrue(testList[0]["name"] == "id1")
        self.assertTrue(testList[1]["name"] == "id2")
        self.assertTrue(testList[0]["infoID1"] == "info1")
        self.assertTrue(testList[0]["infoID2"] == "info2")

    def test_dictToLocation(self):
        testLocationDict = {"locationID": "testID", "displayName": "name", "description": "this is a description"}
        testLocation = self.mensaParser.dictToLocation(testLocationDict)
        self.assertTrue(testLocation.getName() == "name")
        self.assertTrue(testLocation.getDescription() == "this is a description")
        self.assertTrue(testLocation.getID() == "testID")

    def test_mealID(self):
        menuData = {
            "days": [{
                "date": str(datetime.today()),
                "isPast": True,
                "counters": [{
                    "id": "komplett",
                    "displayName": "Komplett Menü",
                    "description": "a test counter",
                    "openingHours": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "color": {
                        "r": 123,
                        "g": 123,
                        "b": 123
                    },
                    "feedback": {
                        "start": str(datetime.now()),
                        "end": str(datetime.now())
                    },
                    "meals": [
                        {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                        }
                    ]
                }]
            }]
        }
        testMealDict = {
                            "knownMealId": "Gebackener Fleischkäse",
                            "name": "Gebackener Fleischkäs",
                            "notices": [],
                            "components": [
                                {
                                    "name": "Fleischkäs",
                                    "notices": []
                                }
                            ],
                            "prices": {
                                "s": "2,85"
                            },
                            "pricingNotice": "This is a price",
                        }
        menuDataJSON = json.dumps(menuData)
        parsedMenuData = self.mensaParser.parseMenuData(menuDataJSON)
        menuDict = dict()
        menuDict['sb'] = parsedMenuData
        menuDict['hom'] = parsedMenuData
        menuDict['musiksb'] = parsedMenuData
        menuDict['htwgtb'] = parsedMenuData
        menuDict['mensagarten'] = parsedMenuData
        menuDict['htwcas'] = parsedMenuData
        menuDict['htwcrb'] = parsedMenuData

        self.mensaParser._mensaModel.update(self.baseData, menuDict, 'de')
        fleischkäsID = parsedMenuData[0]._counters[0]._meals[0].getID()
        fleischkäs2 = self.mensaParser.dictToMeal(testMealDict)
        self.assertEqual(fleischkäsID, fleischkäs2.getID())


if __name__ == '__main__':
    unittest.main()
