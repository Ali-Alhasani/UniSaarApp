//
//  MensaModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct MensaMenuModel: Codable, Sendable, Equatable {
    let daysMenus: [MensaDayModel]
    let filtersLastChanged: String
}

extension MensaMenuModel {
    enum CodingKeys: String, CodingKey {
        case daysMenus = "days"
        case filtersLastChanged
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            daysMenus:          container.value(.daysMenus,          default: []),
            filtersLastChanged: container.value(.filtersLastChanged, default: "")
        )
    }

    static let empty = MensaMenuModel(daysMenus: [], filtersLastChanged: "")
}

struct MensaDayModel: Codable, Sendable, Equatable {
    let date: String
    let countersMeals: [MensaMealsModel]
}

extension MensaDayModel {
    enum CodingKeys: String, CodingKey {
        case date
        case countersMeals = "meals"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            date:         container.value(.date,         default: ""),
            countersMeals: container.value(.countersMeals, default: [])
        )
    }

    static let empty = MensaDayModel(date: "", countersMeals: [])
}

struct MensaMealsModel: Codable, Sendable, Equatable {
    let mealID: Int
    let counterName: String
    let mealDispalyName: String
    let description: String
    let openiningHours: String
    let color: MensaColorModel
    let meals: [String]
    let notices: [String]
}

extension MensaMealsModel {
    enum CodingKeys: String, CodingKey {
        case mealID = "id"
        case counterName
        case mealDispalyName = "mealName"
        case description
        case openiningHours = "openingHours"
        case color
        case meals = "components"
        case notices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            mealID:          container.value(.mealID,          default: 0),
            counterName:     container.value(.counterName,     default: ""),
            mealDispalyName: container.value(.mealDispalyName, default: ""),
            description:     container.value(.description,     default: ""),
            openiningHours:  container.value(.openiningHours,  default: ""),
            color:           container.value(.color,           default: .zero),
            meals:           container.value(.meals,           default: []),
            notices:         container.value(.notices,         default: [])
        )
    }
}

struct MensaColorModel: Codable, Sendable, Equatable {
    let red: Float
    let green: Float
    let blue: Float

    static let zero = MensaColorModel(red: 0, green: 0, blue: 0)
}

extension MensaColorModel {
    enum CodingKeys: String, CodingKey {
        case red = "r"
        case green = "g"
        case blue = "b"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            red:   container.value(.red,   default: Float(0)),
            green: container.value(.green, default: Float(0)),
            blue:  container.value(.blue,  default: Float(0))
        )
    }
}

struct MealDetailsModel: Codable, Sendable, Equatable {
    let mealID: Int
    let mealName: String
    let generalNotices: [MealNotices]
    let counterDescription: String
    let mealComponets: [MealComponents]
    let prices: [MealPrice]
}

extension MealDetailsModel {
    enum CodingKeys: String, CodingKey {
        case mealID = "id"
        case mealName
        case generalNotices
        case counterDescription = "description"
        case mealComponets = "mealComponents"
        case prices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            mealID:             container.value(.mealID,             default: 0),
            mealName:           container.value(.mealName,           default: ""),
            generalNotices:     container.value(.generalNotices,     default: []),
            counterDescription: container.value(.counterDescription, default: ""),
            mealComponets:      container.value(.mealComponets,      default: []),
            prices:             container.value(.prices,             default: [])
        )
    }
}

struct MealComponents: Codable, Sendable, Equatable {
    let componentName: String
    let componentNotices: [MealNotices]
}

extension MealComponents {
    enum CodingKeys: String, CodingKey {
        case componentName
        case componentNotices = "notices"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            componentName:    container.value(.componentName,    default: ""),
            componentNotices: container.value(.componentNotices, default: [])
        )
    }
}

struct MealNotices: Codable, Sendable, Equatable {
    let noticeTag: String
    let noticeDispalyName: String
}

extension MealNotices {
    enum CodingKeys: String, CodingKey {
        case noticeTag = "notice"
        case noticeDispalyName = "displayName"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            noticeTag:         container.value(.noticeTag,         default: ""),
            noticeDispalyName: container.value(.noticeDispalyName, default: "")
        )
    }
}

struct MealPrice: Codable, Sendable, Equatable {
    let priceTagName: String
    let price: String
}

extension MealPrice {
    enum CodingKeys: String, CodingKey {
        case priceTagName = "priceTag"
        case price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            priceTagName: container.value(.priceTagName, default: ""),
            price:        container.value(.price,        default: "")
        )
    }
}

struct MensaInfo: Codable, Sendable, Equatable {
    let locationName: String
    let description: String
    let imageLink: String
}

extension MensaInfo {
    enum CodingKeys: String, CodingKey {
        case locationName = "name"
        case description
        case imageLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            locationName: container.value(.locationName, default: ""),
            description:  container.value(.description,  default: ""),
            imageLink:    container.value(.imageLink,    default: "")
        )
    }
}

// MARK: MensaMenuModel demo data

extension MensaMenuModel {
    nonisolated(unsafe) static let deomJSON: [String: Any] = ["days": [
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
                        ["Tomaten-Zucchini-Bechamelsoße", "Endiviensalat", "Weiße Salatsoße", "Klare Salatsoße", "Fruchtjoghurt"]]
            ]]
    ]]
}

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
