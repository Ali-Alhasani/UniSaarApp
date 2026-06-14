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

struct ChecklistItem {
    let text: String
    var checked = false
    mutating func toggleChecked() {
        checked.toggle()
    }
}
