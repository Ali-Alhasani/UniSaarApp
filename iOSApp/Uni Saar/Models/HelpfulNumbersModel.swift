//
//  HelpfulNumbersModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct HelpfulNumbersModel: Codable, Equatable {
    let numbersLastChanged: String
    let numbers: [NumberModel]
}

extension HelpfulNumbersModel {
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case numbersLastChanged, numbers }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            numbersLastChanged: container.value(.numbersLastChanged, default: ""),
            numbers: container.value(.numbers, default: [])
        )
    }

    static let empty = HelpfulNumbersModel(numbersLastChanged: "", numbers: [])
}

struct NumberModel: Codable, Equatable, Hashable {
    let name: String?
    let number: String?
    let link: String?
    let mail: String?
}

extension NumberModel {
    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case name, number, link, mail }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: container.optionalValue(.name),
            number: container.optionalValue(.number),
            link: container.optionalValue(.link),
            mail: container.optionalValue(.mail)
        )
    }

    static let empty = NumberModel(name: nil, number: nil, link: nil, mail: nil)
}

extension NumberModel {
    nonisolated(unsafe) static let deomJSON: [String: Any] = [
        "name": "Student office",
        "number": "0681 302-5491",
        "link": "https://www.uni-saarland.de/studium/beratung/studierendensekretariat.html",
        "mail": "anmeldung@univw.uni-saarland.de"
    ]
}

extension HelpfulNumbersModel {
    static let helpfulNumbersDemoData = HelpfulNumbersModel(
        numbersLastChanged: "2020-01-26 22:54:42.457799",
        numbers: [
            NumberModel(
                name: "Student office", number: "0681 302-5491",
                link: "https://www.uni-saarland.de/studium/beratung/studierendensekretariat.html",
                mail: "anmeldung@univw.uni-saarland.de"
            ),
            NumberModel(name: "IT Help Desk", number: "0681/302 - 2222", link: nil, mail: "support@hiz-saarland.de"),
            NumberModel(name: "AStA", number: "+49 681 302 2900", link: "https://asta.uni-saarland.de/en", mail: nil),
            NumberModel(name: "Library", number: "+49 681 302 3076", link: nil, mail: nil)
        ]
    )
}
