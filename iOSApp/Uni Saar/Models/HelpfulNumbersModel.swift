//
//  HelpfulNumbersModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
class HelpfulNumbersModel {
    var numbersLastChanged: String
    var numbers: [NumberModel]
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        numbersLastChanged = jsonFromated["numbersLastChanged"].stringValue
        numbers = jsonFromated["numbers"].arrayValue.map {NumberModel(json: $0)}
    }
}
class NumberModel {
    var name: String?
    var number: String?
    var link: String?
    var mail: String?
    init(json: JSON) {
        name = json["name"].string
        number = json["number"].string
        link = json["link"].string
        mail = json["mail"].string
    }
}
extension NumberModel {
    static let deomJSON: [String: Any] = ["name": "Student office", "number": "0681 302-5491", "link":
        "https://www.uni-saarland.de/studium/beratung/studierendensekretariat.html", "mail": "anmeldung@univw.uni-saarland.de"]
}
extension HelpfulNumbersModel {
    static let helpfulNumbersDemoData = HelpfulNumbersModel(json: ["numbersLastChanged": "2020-01-26 22:54:42.457799", "numbers": [
        [
            "name": "Student office",
            "number": "0681 302-5491",
            "link": "https://www.uni-saarland.de/studium/beratung/studierendensekretariat.html",
            "mail": "anmeldung@univw.uni-saarland.de"
        ],
        [
            "name": "IT Help Desk",
            "number": "0681/302 - 2222",
            "mail": "support@hiz-saarland.de"
        ],
        [
            "name": "AStA",
            "number": "+49 681 302 2900",
            "link": "https://asta.uni-saarland.de/en"
        ],
        [
            "name": "Library",
            "number": "+49 681 302 3076"
        ]
        ]])
}
