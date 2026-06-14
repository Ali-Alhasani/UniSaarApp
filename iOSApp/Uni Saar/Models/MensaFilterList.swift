//
//  MensaFilterList.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct MensaFilterModel: Codable, Equatable {
    let locations: [Locations]
    let notices: [Notices]
}

extension MensaFilterModel {
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case locations, notices }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            locations: container.value(.locations, default: []),
            notices: container.value(.notices, default: [])
        )
    }

    init() {
        locations = []
        notices = []
    }
}

struct Locations: Codable, Equatable, Hashable {
    let locationID: String
    let name: String
}

extension Locations {
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case locationID, name }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            locationID: container.value(.locationID, default: ""),
            name: container.value(.name, default: "")
        )
    }
}

struct Notices: Codable, Equatable, Hashable {
    let noticeID: String
    let name: String
    let isAllergen: Bool
    let isNegated: Bool
}

extension Notices {
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case noticeID, name, isAllergen, isNegated }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            noticeID: container.value(.noticeID, default: ""),
            name: container.value(.name, default: ""),
            isAllergen: container.value(.isAllergen, default: false),
            isNegated: container.value(.isNegated, default: false)
        )
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
