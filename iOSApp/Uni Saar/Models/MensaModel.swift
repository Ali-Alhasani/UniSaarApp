//
//  MensaModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
class MensaMenuModel {
    var daysMenus: [MensaDayModel]
    var filtersLastChanged: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        let days = jsonFromated["days"].arrayValue
        self.daysMenus = days.map { MensaDayModel(json: $0.dictionaryValue)}
        self.filtersLastChanged = jsonFromated["filtersLastChanged"].stringValue
    }
}

class MensaDayModel {
    var date: String
    var countersMeals: [MensaMealsModel]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.date = jsonFromated["date"].stringValue
        let counters = jsonFromated["meals"].arrayValue
        self.countersMeals = counters.map {MensaMealsModel(json: $0.dictionaryValue)}
    }
}

class MensaMealsModel {
    var mealID: Int
    var counterName: String
    var mealDispalyName: String
    var description: String
    var openiningHours: String
    var color: MensaColorModel
    var meals: [String]
    var notices: [String]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.mealID = jsonFromated["id"].intValue
        self.mealDispalyName = jsonFromated["mealName"].stringValue
        self.counterName = jsonFromated["counterName"].stringValue
        self.description = jsonFromated["description"].stringValue
        self.openiningHours = jsonFromated["openingHours"].stringValue
        self.color = MensaColorModel(json: jsonFromated["color"].dictionaryValue)
        self.meals = jsonFromated["components"].arrayObject as? [String]  ?? []
        self.notices = jsonFromated["notices"].arrayObject as? [String]  ?? []
    }
}
class MensaColorModel {
    var red: Float
    var green: Float
    var blue: Float
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.red = jsonFromated["r"].floatValue
        self.green = jsonFromated["g"].floatValue
        self.blue = jsonFromated["b"].floatValue
    }
}
class MealDetailsModel {
    var mealID: Int
    var mealName: String
    var generalNotices: [MealNotices]
    var counterDescription: String
    var mealComponets: [MealComponents]
    var prices: [MealPrice]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.mealID = jsonFromated["id"].intValue
        self.mealName = jsonFromated["mealName"].stringValue
        self.counterDescription = jsonFromated["description"].stringValue
        self.generalNotices = jsonFromated["generalNotices"].arrayValue.map {MealNotices(json: $0.dictionaryValue)}
        self.prices = jsonFromated["prices"].arrayValue.map {MealPrice(json: $0.dictionaryValue)}
        self.mealComponets = jsonFromated["mealComponents"].arrayValue.map {MealComponents(json: $0.dictionaryValue)}
    }
}
class MealComponents {
    var componentName: String
    var componentNotices: [MealNotices]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.componentName = jsonFromated["componentName"].stringValue
        let notices  = jsonFromated["notices"].arrayValue
        self.componentNotices = notices.map {MealNotices(json: $0.dictionaryValue)}
    }
}
class MealNotices {
    var noticeTag: String
    var noticeDispalyName: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.noticeTag = jsonFromated["notice"].stringValue
        self.noticeDispalyName = jsonFromated["displayName"].stringValue
    }
}
class MealPrice {
    var priceTagName: String
    var price: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.priceTagName = jsonFromated["priceTag"].stringValue
        self.price = jsonFromated["price"].stringValue
    }
}
class MensaInfo {
    var locationName: String
    var description: String
    var imageLink: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        locationName = jsonFromated["name"].stringValue
        description = jsonFromated["description"].stringValue
        imageLink = jsonFromated["imageLink"].stringValue
    }
}
// MARK: MensaMenuModel demo data
extension MensaMenuModel {
    // note maybe we should return the notices code in order to do the filtering?!
    //one array for meals name and the other for notices??!
    static let deomJSON = ["days": [
        ["date": "today", "meals":
            [
                [
                    "counterName": "Complete Meal", "mealName": "Picadillo Argentinisches Hackfleischgericht",
                    "openingHours": "11:30-14:15",
                    "color": ["r": 217, "g": 38, "b": 26],
                    "components": [
                        "Fussili", "Pusztasalat", "Tomatensuppe", "Stracciatella-Bananen-Sahnequark"
                    ], "notices": []
                ], ["counterName": "Vegetarian Meal", "mealName": "PastaBoccolotti", "description": "description",
                    "openingHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "components":
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]
                ], ["counterName": "Free Flow", "mealName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openingHours": "11:30-14:15",
                    "color": ["r": 245, "g": 204, "b": 43], "components":
                        ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]
                ], ["counterName": "Free Flow", "mealName": "Kartoffelgratin", "description": "description", "openingHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "components":
                        ["Bunter Blattsalat", "Balsamico-Dressing"]
                ], ["counterName": "Free Flow", "mealName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                    "openingHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "components":
                        [:]
                ], ["counterName": "Free Flow", "mealName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                    "openingHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "components":
                        ["Pommes Frites"]
                ], ["counterName": "Free Flow", "mealName": "Salatbuffet", "description": "description", "openingHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "components":
                        ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                         "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]
                ]
            ]
        ]]]
    static let menuDemoData = MensaMenuModel(json: ["days": [
        ["date": "today", "counters":
            [
                [
                    "countersName": "Complete Meal", "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht",
                    "openiningHours": "11:30-14:15",
                    "color": ["r": 217, "g": 38, "b": 26],
                    "meals": [
                        "Fussili", "Pusztasalat", "Tomatensuppe", "Stracciatella-Bananen-Sahnequark"
                    ], "notices": []
                ], ["countersName": "Vegetarian Meal", "mealDispalyName": "PastaBoccolotti", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                    "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Bunter Blattsalat", "Balsamico-Dressing"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        [:]
                ], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Pommes Frites"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                         "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]
                ]
            ]
        ], ["date": "2019-12-10", "counters":
            [
                [
                    "countersName": "Complete Meal", "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht",
                    "openiningHours": "11:30-14:15",
                    "color": ["r": 217, "g": 38, "b": 26],
                    "meals": [
                        "Fussili", "Pusztasalat", "Tomatensuppe", "Stracciatella-Bananen-Sahnequark"
                    ], "notices": []
                ], ["countersName": "Vegetarian Meal", "mealDispalyName": "PastaBoccolotti", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                    "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Bunter Blattsalat", "Balsamico-Dressing"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        [:]
                ], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Pommes Frites"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                         "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]
                ]
            ]
        ], ["date": "2019-12-11", "counters":
            [
                [
                    "countersName": "Complete Meal", "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht",
                    "openiningHours": "11:30-14:15",
                    "color": ["r": 217, "g": 38, "b": 26],
                    "meals": [
                        "Fussili", "Pusztasalat", "Tomatensuppe", "Stracciatella-Bananen-Sahnequark"
                    ], "notices": []
                ], ["countersName": "Vegetarian Meal", "mealDispalyName": "PastaBoccolotti", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                    "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Bunter Blattsalat", "Balsamico-Dressing"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        [:]
                ], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Pommes Frites"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                         "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]
                ]
            ]
        ], ["date": "2019-12-12", "counters":
            [
                [
                    "countersName": "Complete Meal", "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht",
                    "openiningHours": "11:30-14:15",
                    "color": ["r": 217, "g": 38, "b": 26],
                    "meals": [
                        "Fussili", "Pusztasalat", "Tomatensuppe", "Stracciatella-Bananen-Sahnequark"
                    ], "notices": []
                ], ["countersName": "Vegetarian Meal", "mealDispalyName": "PastaBoccolotti", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                    "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Bunter Blattsalat", "Balsamico-Dressing"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        [:]
                ], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                    "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                        ["Pommes Frites"]
                ], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                        ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                         "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]
                ]
            ]
        ]]
        ]
    )
    static let emptyMenuDemoData = MensaMenuModel(json: [:])
}

// MARK: MensaMenuModel demo data
extension MensaDayModel {
    static let menuDemoData: [String: Any] = ["date": "2019-12-10", "counters":
        [
            "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht", "description": "description", "openiningHours": "11:30-14:15",
            "color": ["r": 217, "g": 38, "b": 26],
            "meals": [
                ["name": "Fussili"], ["name": "Pusztasalat"], ["name": "Tomatensuppe"], ["name": "Stracciatella-Bananen-Sahnequark"]
            ]
        ]
    ]
}
// MARK: MensaMealsModel demo data
extension MensaMealsModel {
    static let mensaDemoData = [MensaMealsModel(json:
        ["mealDispalyName": "Picadillo Argentinisches Hackfleischgericht", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 217, "g": 38, "b": 26], "meals":
                [
                    ["name": "Fussili"], ["name": "Pusztasalat"], ["name": "Tomatensuppe"], ["name": "Stracciatella-Bananen-Sahnequark"]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "PastaBoccolotti", "description": "description", "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
            [
                ["name": "Tomaten-Zucchini-Bechamelsoße"], ["name": "Endiviensalat"], ["name": "Weiße Salatsoße"], ["name": "Klare Salatsoße"], ["name": "Fruchtjoghurt"]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 245, "g": 204, "b": 43], "meals":
                [
                    ["name": "Kartoffelgratin"], ["name": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln"],
                    ["name": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf"], ["name": "Salatbuffet"]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 245, "g": 204, "b": 43], "meals":
                [
                    ["name": "Bunter Blattsalat"], ["name": "Balsamico-Dressing"]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 245, "g": 204, "b": 43], "meals":
                [
                    [:]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 245, "g": 204, "b": 43], "meals":
                [
                    ["name": "Pommes Frites"]
            ]
    ]), MensaMealsModel(json:
        ["mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 245, "g": 204, "b": 43], "meals":
                [
                    ["name": "Tomatensalat"], ["name": "Weisskraut"], ["name": "Gurken"], ["name": "Zwiebel Ringe"], ["name": "Karotten"],
                    ["name": "Gemischter Paprika"], ["name": "Mais"], ["name": "Peperoni"],
                    ["name": "Lollo Bianco"], ["name": "Radicchio"], ["name": "Klare Salatsoße"]
            ]
    ])
    ]
}

extension MealDetailsModel {
    //mealName is can optional here
    static let mealDemoData = MealDetailsModel(json:
        ["mealName": "Fischfilet im Backteig", "description": "Entrance A and B (to the left)", "generalNotices": [
            ["notice": "ba", "displayName": "raising agent"], ["notice": "fnf", "displayName": "fish from sustainable fishing"], ["notice": "fi", "displayName": "Fish"]
            ], "prices": [["priceTag": "Studenten", "price": "3,10"], ["priceTag": "Bedienstete", "price": "5,25"], ["priceTag": "Gäste", "price": "7,30"]], "mealComponets":
                [["componentName": "Remouladensoße", "notices": [
                    ["notice": "ba", "displayName": "raising agent"], ["notice": "fnf", "displayName": "fish from sustainable fishing"], ["notice": "fi", "displayName": "Fish"]]],
                 ["componentName": "Petersilienkartoffel (Kartoffeln aus biologischem Anbau)", "notices": [
                    ]],
                 ["componentName": "Karottensalat", "notices": [
                    ["notice": "fs", "displayName": "artificial colouring"], ["notice": "ei", "displayName": "Chicken Egg"], ["notice": "la", "displayName": "Milk and lactose"],
                    ["notice": "snf", "displayName": "Mustard"]]
                    ],
                 ["componentName": "Obst", "notices": [
                    ]]
            ]
    ])
    static let emptyMealDemoData = MealDetailsModel(json: [:])
}
//extra model for notice it will be array of ["notice": "ba", "displayName": "raising agent"]
//fourth API is the mensa info, to show the description and the location open hours .. etc
