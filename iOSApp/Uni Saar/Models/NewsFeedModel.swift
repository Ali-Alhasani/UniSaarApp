//
//  NewsFeedModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

class NewsFeedModel {
    var newsItemCount: Int
    var categoriesLastChanged: String
    var hasNextPage: Bool
    var newsList = [NewsModel]()
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        newsItemCount = jsonFromated["itemCount"].intValue
        categoriesLastChanged = jsonFromated["categoriesLastChanged"].stringValue
        hasNextPage = jsonFromated["hasNextPage"].boolValue
        newsList = jsonFromated["items"].arrayValue.map {NewsModel(json: $0.dictionaryValue)}
    }
}
class NewsModel {
    var annoucementDate: String
    var title: String
    var newsID: Int
    var subTitle: String?
    var categoryName: [String: String]
    var imageURLString: String?
    var newslink: String?
    var isEvent: Bool = false
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        if let happeningDate =  jsonFromated["happeningDate"].string {
            self.annoucementDate = happeningDate
            self.isEvent = true
        } else {
            self.annoucementDate = jsonFromated["publishedDate"].stringValue
        }
        self.title = jsonFromated["title"].stringValue
        self.newsID = jsonFromated["id"].intValue
        self.subTitle = jsonFromated["description"].stringValue
        self.categoryName = jsonFromated["categories"].dictionaryObject as? [String: String] ?? [:]
        self.imageURLString = jsonFromated["imageURL"].stringValue
        self.newslink = jsonFromated["link"].stringValue
    }
}

class NewsCategories {
    var categoryID: Int
    var categoryName: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.categoryID = jsonFromated["id"].intValue
        self.categoryName = jsonFromated["name"].stringValue
    }
}
extension NewsModel {
    static let deomJSON: [String: Any] =  ["date": "12/05/2019", "title": "„Echt jetzt?“ – Eine öffentliche Vortragsreihe über die Realität", "id": 100,
                                           "description": """
        Ihr Thema ist dieses Mal nichts Geringeres als die Realität: Eine Physik-Professorin und ein Physik-Professor der Universität des Saarlandes
        organisieren auch in diesem Wintersemester eine interdisziplinäre öffentliche Vortragsreihe im Filmhaus Saarbrücken.
        """, "imageURL": "", "category": ["categoryName"]]
}
// NewsFeedModel demo data
extension NewsFeedModel {
    static let newsDemoData = NewsFeedModel(json:
        ["itemCount": 5, "items": [
            ["date": "12/05/2019", "title": "„Echt jetzt?“ – Eine öffentliche Vortragsreihe über die Realität", "id": 100,
             "description": """
                Ihr Thema ist dieses Mal nichts Geringeres als die Realität: Eine Physik-Professorin und ein Physik-Professor der Universität des Saarlandes
                organisieren auch in diesem Wintersemester eine interdisziplinäre öffentliche Vortragsreihe im Filmhaus Saarbrücken.
                """, "imageURL": "", "category": ["categoryName"]],
            ["date": "12/04/2019", "title": "Probestudium Physik für Schülerinnen und Schüler beschäftigt sich mit Quantenwelten", "id": 100,
             "description": """
                Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein „Probestudium Physik“.
                Es bietet Schülerinnen und Schülern der gymnasialen Oberstufe die Möglichkeit, samstags an Vorlesungen und einem physikalischen Praktikum teilzunehmen,
                um so einen realistischen Einblick vom Physik-Studium an der Saar-Uni zu erhalten.
                """,
             "category": ["categoryName"],
             "imageURL": ""],
            ["date": "11/30/2019", "title": "Neue Webseiten für die Universität des Saarlandes", "id": 100,
             "description": """
                Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein „Probestudium Physik“.
                Es bietet Schülerinnen und Schülern der gymnasialen Oberstufe die Möglichkeit
                """,
             "category": ["categoryName"],
             "imageURL": "https://www.uni-saarland.de/fileadmin/upload/_processed_/6/d/csm_Ezziddin_Samer_2_b69ceceaca.jpg"]
            ,
            ["date": "11/30/2019", "title": "Neue Webseiten für die Universität des Saarlandes", "id": 100,
             "description": """
                Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein „Probestudium Physik“.
                Es bietet Schülerinnen und Schülern der gymnasialen Oberstufe die Möglichkeit
                """,
             "category": ["categoryName"],
             "imageURL": "https://www.uni-saarland.de/fileadmin/upload/_processed_/6/d/csm_Ezziddin_Samer_2_b69ceceaca.jpg"]
            ]
    ])
}
