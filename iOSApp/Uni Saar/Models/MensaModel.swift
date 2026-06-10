//
//  MensaModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

final class MensaMenuModel: Sendable {
    let daysMenus: [MensaDayModel]
    let filtersLastChanged: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        let days = jsonFromated["days"].arrayValue
        daysMenus = days.map { MensaDayModel(json: $0.dictionaryValue) }
        filtersLastChanged = jsonFromated["filtersLastChanged"].stringValue
    }
}

final class MensaDayModel: Sendable {
    let date: String
    let countersMeals: [MensaMealsModel]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        date = jsonFromated["date"].stringValue
        let counters = jsonFromated["meals"].arrayValue
        countersMeals = counters.map { MensaMealsModel(json: $0.dictionaryValue) }
    }
}

final class MensaMealsModel: Sendable {
    let mealID: Int
    let counterName: String
    let mealDispalyName: String
    let description: String
    let openiningHours: String
    let color: MensaColorModel
    let meals: [String]
    let notices: [String]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        mealID = jsonFromated["id"].intValue
        mealDispalyName = jsonFromated["mealName"].stringValue
        counterName = jsonFromated["counterName"].stringValue
        description = jsonFromated["description"].stringValue
        openiningHours = jsonFromated["openingHours"].stringValue
        color = MensaColorModel(json: jsonFromated["color"].dictionaryValue)
        meals = jsonFromated["components"].arrayObject as? [String] ?? []
        notices = jsonFromated["notices"].arrayObject as? [String] ?? []
    }
}

final class MensaColorModel: Sendable {
    let red: Float
    let green: Float
    let blue: Float
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        red = jsonFromated["r"].floatValue
        green = jsonFromated["g"].floatValue
        blue = jsonFromated["b"].floatValue
    }
}

final class MealDetailsModel: Sendable {
    let mealID: Int
    let mealName: String
    let generalNotices: [MealNotices]
    let counterDescription: String
    let mealComponets: [MealComponents]
    let prices: [MealPrice]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        mealID = jsonFromated["id"].intValue
        mealName = jsonFromated["mealName"].stringValue
        counterDescription = jsonFromated["description"].stringValue
        generalNotices = jsonFromated["generalNotices"].arrayValue.map { MealNotices(json: $0.dictionaryValue) }
        prices = jsonFromated["prices"].arrayValue.map { MealPrice(json: $0.dictionaryValue) }
        mealComponets = jsonFromated["mealComponents"].arrayValue.map { MealComponents(json: $0.dictionaryValue) }
    }
}

final class MealComponents: Sendable {
    let componentName: String
    let componentNotices: [MealNotices]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        componentName = jsonFromated["componentName"].stringValue
        let notices = jsonFromated["notices"].arrayValue
        componentNotices = notices.map { MealNotices(json: $0.dictionaryValue) }
    }
}

final class MealNotices: Sendable {
    let noticeTag: String
    let noticeDispalyName: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        noticeTag = jsonFromated["notice"].stringValue
        noticeDispalyName = jsonFromated["displayName"].stringValue
    }
}

final class MealPrice: Sendable {
    let priceTagName: String
    let price: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        priceTagName = jsonFromated["priceTag"].stringValue
        price = jsonFromated["price"].stringValue
    }
}

final class MensaInfo: Sendable {
    let locationName: String
    let description: String
    let imageLink: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        locationName = jsonFromated["name"].stringValue
        description = jsonFromated["description"].stringValue
        imageLink = jsonFromated["imageLink"].stringValue
    }
}

// MARK: MensaMenuModel demo data

extension MensaMenuModel {
    /// note maybe we should return the notices code in order to do the filtering?!
    /// one array for meals name and the other for notices??!
    nonisolated(unsafe) static let deomJSON = ["days": [
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]], ["counterName": "Free Flow", "mealName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openingHours": "11:30-14:15",
                                                                                                                                     "color": ["r": 245, "g": 204, "b": 43], "components":
                                                                                                                                         ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]], ["counterName": "Free Flow", "mealName": "Kartoffelgratin", "description": "description", "openingHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "components":
                    ["Bunter Blattsalat", "Balsamico-Dressing"]], ["counterName": "Free Flow", "mealName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                                                                   "openingHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "components":
                                                                       [:]], ["counterName": "Free Flow", "mealName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                                                                              "openingHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "components":
                                                                                  ["Pommes Frites"]], ["counterName": "Free Flow", "mealName": "Salatbuffet", "description": "description", "openingHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "components":
                    ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                     "Mais", "Peperoni", "Lollo Biondo", "Radicchio", "Klare Salatsoße"]]
            ]]
    ]]
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                                                                                                                                     "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                                                                         ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Bunter Blattsalat", "Balsamico-Dressing"]], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                                                                   "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                       [:]], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                                                                              "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                  ["Pommes Frites"]], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                     "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]]
            ]], ["date": "2019-12-10", "counters":
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                                                                                                                                     "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                                                                         ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Bunter Blattsalat", "Balsamico-Dressing"]], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                                                                   "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                       [:]], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                                                                              "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                  ["Pommes Frites"]], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                     "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]]
            ]], ["date": "2019-12-11", "counters":
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                                                                                                                                     "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                                                                         ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Bunter Blattsalat", "Balsamico-Dressing"]], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                                                                   "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                       [:]], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                                                                              "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                  ["Pommes Frites"]], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                     "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]]
            ]], ["date": "2019-12-12", "counters":
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]], ["countersName": "Free Flow", "mealDispalyName": "Feuriges Gemüse-Fischcurry mit Ingwerreis", "description": "description", "openiningHours": "11:30-14:15",
                                                                                                                                     "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                                                                         ["Kartoffelgratin", "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "Salatbuffet"]], ["countersName": "Free Flow", "mealDispalyName": "Kartoffelgratin", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Bunter Blattsalat", "Balsamico-Dressing"]], ["countersName": "Free Flow", "mealDispalyName": "Hähnchenbrust mit Cassis-Soße und Herzoginkartoffeln", "description": "description",
                                                                   "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                       [:]], ["countersName": "Free Flow", "mealDispalyName": "Gebratenes Fleischwürstchen mit süssem Meerrettichsenf", "description": "description",
                                                                              "openiningHours": "11:30-14:15", "color": ["r": 245, "g": 204, "b": 43], "meals":
                                                                                  ["Pommes Frites"]], ["countersName": "Free Flow", "mealDispalyName": "Salatbuffet", "description": "description", "openiningHours": "11:30-14:15", "color":
                    ["r": 245, "g": 204, "b": 43], "meals":
                    ["Tomatensalat", "Weisskraut", "Gurken", "Zwiebel Ringe", "Karotten", "Gemischter Paprika",
                     "Mais", "Peperoni", "Lollo Bianco", "Radicchio", "Klare Salatsoße"]]
            ]]
    ]])
    static let emptyMenuDemoData = MensaMenuModel(json: [:])
}

// MARK: MensaMenuModel demo data

extension MensaDayModel {
    nonisolated(unsafe) static let menuDemoData: [String: Any] = ["date": "2019-12-10", "counters":
        [
            "mealDispalyName": "Picadillo Argentinisches Hackfleischgericht", "description": "description", "openiningHours": "11:30-14:15",
            "color": ["r": 217, "g": 38, "b": 26],
            "meals": [
                ["name": "Fussili"], ["name": "Pusztasalat"], ["name": "Tomatensuppe"], ["name": "Stracciatella-Bananen-Sahnequark"]
            ]
        ]]
}

// MARK: MensaMealsModel demo data

extension MensaMealsModel {
    static let mensaDemoData = [MensaMealsModel(json:
        ["mealDispalyName": "Picadillo Argentinisches Hackfleischgericht", "description": "description", "openiningHours": "11:30-14:15", "color":
            ["r": 217, "g": 38, "b": 26], "meals":
            [
                ["name": "Fussili"], ["name": "Pusztasalat"], ["name": "Tomatensuppe"], ["name": "Stracciatella-Bananen-Sahnequark"]
            ]]), MensaMealsModel(json:
        ["mealDispalyName": "PastaBoccolotti", "description": "description", "openiningHours": "11:30-14:15", "color": ["r": 21, "g": 135, "b": 207], "meals":
            [
                ["name": "Tomaten-Zucchini-Bechamelsoße"], ["name": "Endiviensalat"], ["name": "Weiße Salatsoße"], ["name": "Klare Salatsoße"], ["name": "Fruchtjoghurt"]
            ]])]
}

extension MealDetailsModel {
    static let mealDemoData = MealDetailsModel(json:
        ["mealName": "Fischfilet im Backteig", "description": "Entrance A and B (to the left)", "generalNotices": [
            ["notice": "ba", "displayName": "raising agent"], ["notice": "fnf", "displayName": "fish from sustainable fishing"], ["notice": "fi", "displayName": "Fish"]
        ], "prices": [["priceTag": "Studenten", "price": "3,10"], ["priceTag": "Bedienstete", "price": "5,25"], ["priceTag": "Gäste", "price": "7,30"]], "mealComponets":
            [["componentName": "Remouladensoße", "notices": [
                ["notice": "ba", "displayName": "raising agent"], ["notice": "fnf", "displayName": "fish from sustainable fishing"], ["notice": "fi", "displayName": "Fish"]
            ]],
            ["componentName": "Petersilienkartoffel (Kartoffeln aus biologischem Anbau)", "notices": [
            ]],
            ["componentName": "Karottensalat", "notices": [
                ["notice": "fs", "displayName": "artificial colouring"], ["notice": "ei", "displayName": "Chicken Egg"], ["notice": "la", "displayName": "Milk and lactose"],
                ["notice": "snf", "displayName": "Mustard"]
            ]],
            ["componentName": "Obst", "notices": [
            ]]]])
    static let emptyMealDemoData = MealDetailsModel(json: [:])
}
