//
//  NewsFeedModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct NewsFeedModel: Codable, Sendable, Equatable {
    let newsItemCount: Int
    let categoriesLastChanged: String
    let hasNextPage: Bool
    let newsList: [NewsModel]
}

extension NewsFeedModel {
    enum CodingKeys: String, CodingKey {
        case newsItemCount = "itemCount"
        case categoriesLastChanged
        case hasNextPage
        case newsList = "items"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            newsItemCount:         container.value(.newsItemCount,         default: 0),
            categoriesLastChanged: container.value(.categoriesLastChanged, default: ""),
            hasNextPage:           container.value(.hasNextPage,           default: false),
            newsList:              container.value(.newsList,              default: [])
        )
    }

    static let empty = NewsFeedModel(
        newsItemCount: 0, categoriesLastChanged: "",
        hasNextPage: false, newsList: []
    )
}

struct NewsModel: Codable, Sendable, Equatable {
    let annoucementDate: String
    let title: String
    let newsID: Int
    let subTitle: String?
    let categoryName: [String: String]
    let imageURLString: String?
    let newslink: String?
    let isEvent: Bool
}

extension NewsModel {
    enum CodingKeys: String, CodingKey {
        case happeningDate, publishedDate, title
        case newsID = "id"
        case subTitle = "description"
        case categoryName = "categories"
        case imageURLString = "imageURL"
        case newslink = "link"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let (date, event) = try Self.resolveDate(container)
        try self.init(
            annoucementDate: date,
            title:           container.value(.title,          default: ""),
            newsID:          container.value(.newsID,         default: 0),
            subTitle:        container.optionalValue(.subTitle),
            categoryName:    container.value(.categoryName,   default: [:]),
            imageURLString:  container.optionalValue(.imageURLString),
            newslink:        container.optionalValue(.newslink),
            isEvent:         event
        )
    }

    private static func resolveDate(
        _ container: KeyedDecodingContainer<CodingKeys>
    ) throws -> (date: String, isEvent: Bool) {
        if let happening = try container.optionalValue(.happeningDate, as: String.self) {
            return (happening, true)
        }
        return (try container.value(.publishedDate, default: ""), false)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(annoucementDate, forKey: isEvent ? .happeningDate : .publishedDate)
        try container.encode(title, forKey: .title)
        try container.encode(newsID, forKey: .newsID)
        try container.encodeIfPresent(subTitle, forKey: .subTitle)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encodeIfPresent(imageURLString, forKey: .imageURLString)
        try container.encodeIfPresent(newslink, forKey: .newslink)
    }

    static let empty = NewsModel(
        annoucementDate: "", title: "", newsID: 0,
        subTitle: nil, categoryName: [:],
        imageURLString: nil, newslink: nil, isEvent: false
    )
}

struct NewsCategories: Codable, Sendable, Equatable, Hashable {
    let categoryID: Int
    let categoryName: String
}

extension NewsCategories {
    enum CodingKeys: String, CodingKey {
        case categoryID = "id"
        case categoryName = "name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            categoryID:   container.value(.categoryID,   default: 0),
            categoryName: container.value(.categoryName, default: "")
        )
    }
}

extension NewsModel {
    nonisolated(unsafe) static let deomJSON: [String: Any] = [
        "date": "12/05/2019",
        "title": "Echt jetzt? – Eine öffentliche Vortragsreihe über die Realität",
        "id": 100,
        "description": """
        Ihr Thema ist dieses Mal nichts Geringeres als die Realität: Eine Physik-Professorin und ein Physik-Professor der Universität des Saarlandes
        organisieren auch in diesem Wintersemester eine interdisziplinäre öffentliche Vortragsreihe im Filmhaus Saarbrücken.
        """,
        "imageURL": "",
        "category": ["categoryName"]
    ]
}

// MARK: NewsFeedModel demo data

extension NewsFeedModel {
    static let newsDemoData = NewsFeedModel(
        newsItemCount: 5,
        categoriesLastChanged: "",
        hasNextPage: false,
        newsList: [
            NewsModel(annoucementDate: "12/05/2019", title: "Echt jetzt? – Eine öffentliche Vortragsreihe über die Realität", newsID: 100,
                      subTitle: "Ihr Thema ist dieses Mal nichts Geringeres als die Realität: Eine Physik-Professorin und ein Physik-Professor der Universität des Saarlandes organisieren auch in diesem Wintersemester eine interdisziplinäre öffentliche Vortragsreihe im Filmhaus Saarbrücken.",
                      categoryName: [:], imageURLString: "", newslink: nil, isEvent: false),
            NewsModel(annoucementDate: "12/04/2019", title: "Probestudium Physik für Schülerinnen und Schüler beschäftigt sich mit Quantenwelten", newsID: 100,
                      subTitle: "Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein \"Probestudium Physik\".",
                      categoryName: [:], imageURLString: "", newslink: nil, isEvent: false),
            NewsModel(annoucementDate: "11/30/2019", title: "Neue Webseiten für die Universität des Saarlandes", newsID: 100,
                      subTitle: "Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein \"Probestudium Physik\".",
                      categoryName: [:], imageURLString: "https://www.uni-saarland.de/fileadmin/upload/_processed_/6/d/csm_Ezziddin_Samer_2_b69ceceaca.jpg", newslink: nil, isEvent: false),
            NewsModel(annoucementDate: "11/30/2019", title: "Neue Webseiten für die Universität des Saarlandes", newsID: 100,
                      subTitle: "Im Januar und Februar 2020 veranstaltet die Fachrichtung Physik der Universität des Saarlandes wieder ein \"Probestudium Physik\".",
                      categoryName: [:], imageURLString: "https://www.uni-saarland.de/fileadmin/upload/_processed_/6/d/csm_Ezziddin_Samer_2_b69ceceaca.jpg", newslink: nil, isEvent: false)
        ]
    )
}
