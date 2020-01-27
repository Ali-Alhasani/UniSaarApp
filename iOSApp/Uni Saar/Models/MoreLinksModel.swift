//
//  MoreLinksModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
class MoreModel {
    var linksLastChanged: String
    var links: [MoreLinksModel]

    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.linksLastChanged = jsonFromated["linksLastChanged"].stringValue
        self.links = jsonFromated["links"].arrayValue.map {MoreLinksModel(json: $0)}
    }
}

class MoreLinksModel {
    var displayName: String
    var url: String
    init(json: JSON) {
        let jsonFromated = JSON(json)
        self.displayName = jsonFromated["name"].stringValue
        self.url = jsonFromated["link"].stringValue
    }
}

extension MoreModel {
    static let demoData = MoreModel(json: ["linksLastChanged": "2020-01-20 17:42:14",
                                           "language": "de", "links": [
                                            [
                                                "name": "Welcome Centre",
                                                "link": "https://www.uni-saarland.de/en/global/welcome-center.html"
                                            ],
                                            [
                                                "name": "AStA",
                                                "link": "https://asta.uni-saarland.de/en/"
                                            ],
                                            [
                                                "name": "Busfahrplan",
                                                "link": "https://www.saarfahrplan.de"
                                            ],
                                            [
                                                "name": "Hochschulsport",
                                                "link": "https://www.uni-saarland.de/en/institution/sports.html"
                                            ]
        ]])
}
extension MoreLinksModel {
    static let deomJSON = ["name": "Welcome Centre",
                           "link": "https://www.uni-saarland.de/en/global/welcome-center.html"
    ]
}
