//
//  MensaFilterList.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

final class MensaFilterModel: Sendable {
    let locations: [Locations]
    let notices: [Notices]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        locations = jsonFromated["locations"].arrayValue.map { Locations(json: $0.dictionaryValue) }
        notices = jsonFromated["notices"].arrayValue.map { Notices(json: $0.dictionaryValue) }
    }

    init() {
        locations = []
        notices = []
    }
}

final class Locations: Sendable {
    let locationID: String
    let name: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        locationID = jsonFromated["locationID"].stringValue
        name = jsonFromated["name"].stringValue
    }

    init(locationID: String, name: String) {
        self.locationID = locationID
        self.name = name
    }
}

final class Notices: Sendable {
    let noticeID: String
    let name: String
    let isAllergen: Bool
    let isNegated: Bool
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        noticeID = jsonFromated["noticeID"].stringValue
        name = jsonFromated["name"].stringValue
        isAllergen = jsonFromated["isAllergen"].boolValue
        isNegated = jsonFromated["isNegated"].boolValue
    }

    init(noticeID: String, name: String, isAllergen: Bool, isNegated: Bool) {
        self.noticeID = noticeID
        self.name = name
        self.isAllergen = isAllergen
        self.isNegated = isNegated
    }
}

/// this just mock model to gives us a  clear perspective on the API design, by getting into the mindset of being a client of the API before it exists.
class FilterList {
    enum Filter: Int, CaseIterable {
        case location, dispalyAllergen, allergenList
    }

    private var mensaLocationsList: [ChecklistItem] = []
    private var emptyList: [ChecklistItem] = []
    private var isDispalyAllergen: Bool = true
    private var allergenList: [ChecklistItem] = []
    init() {
        mensaLocationsList = [
            ChecklistItem(text: "Mensa/Mensacafé Saarbrücken"),
            ChecklistItem(text: "Mensa Homburg"),
            ChecklistItem(text: "Mensagarden"),
            ChecklistItem(text: "Cafeteria Hochschule für Musik Saar")
        ]
        emptyList = [ChecklistItem(text: "Toggle all")]
        allergenList = [
            ChecklistItem(text: "Artificial colouring"),
            ChecklistItem(text: "Preservatives"),
            ChecklistItem(text: "Antioxidants"),
            ChecklistItem(text: "Flavour enhancer"),
            ChecklistItem(text: "Sulphurised"),
            ChecklistItem(text: "Blackened"),
            ChecklistItem(text: "Pork"),
            ChecklistItem(text: "Alcohol"),
            ChecklistItem(text: "Nuts"),
            ChecklistItem(text: "Without pork")
        ]
    }

    func filterList(for fliter: Filter) -> [ChecklistItem] {
        switch fliter {
        case .location:
            mensaLocationsList
        case .dispalyAllergen:
            emptyList
        case .allergenList:
            allergenList
        }
    }
}

struct ChecklistItem {
    let text: String
    var checked = false
    mutating func toggleChecked() {
        checked.toggle()
    }
}
