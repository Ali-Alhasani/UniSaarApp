//
//  MoreLinksModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

final class MoreModel: Sendable {
    let linksLastChanged: String
    let links: [MoreLinksModel]

    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.linksLastChanged = jsonFromated["linksLastChanged"].stringValue
        let arrayLinks = jsonFromated["links"].arrayValue
        var tempLinks: [MoreLinksModel] = []
        for (index, link) in arrayLinks.enumerated() {
            tempLinks.append(MoreLinksModel(json: link, index: index))
        }
        links = tempLinks
    }
}

final class MoreLinksModel: Sendable {
    let displayName: String
    let url: String
    let index: Int
    init(json: JSON, index: Int) {
        let jsonFromated = JSON(json)
        self.displayName = jsonFromated["name"].stringValue
        self.url = jsonFromated["link"].stringValue
        self.index = index
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
