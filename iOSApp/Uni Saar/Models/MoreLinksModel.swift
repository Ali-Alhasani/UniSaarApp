//
//  MoreLinksModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct MoreModel: Codable, Equatable {
    let linksLastChanged: String
    let links: [MoreLinksModel]
}

extension MoreModel {
    enum CodingKeys: String, CodingKey { case linksLastChanged, links }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lastChanged: String = try container.value(.linksLastChanged, default: "")
        let wireLinks: [MoreLinksModel.Wire] = try container.value(.links, default: [])
        self.init(
            linksLastChanged: lastChanged,
            links: wireLinks.enumerated().map { index, wire in
                MoreLinksModel(displayName: wire.displayName, url: wire.url, index: index)
            }
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(linksLastChanged, forKey: .linksLastChanged)
        let wireLinks = links.map { MoreLinksModel.Wire(displayName: $0.displayName, url: $0.url) }
        try container.encode(wireLinks, forKey: .links)
    }

    static let empty = MoreModel(linksLastChanged: "", links: [])
}

struct MoreLinksModel: Equatable, Hashable {
    let displayName: String
    let url: String
    let index: Int
}

extension MoreLinksModel {
    struct Wire: Codable {
        let displayName: String
        let url: String
    }
}

extension MoreLinksModel.Wire {
    enum CodingKeys: String, CodingKey {
        case displayName = "name"
        case url = "link"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            displayName: container.value(.displayName, default: ""),
            url: container.value(.url, default: "")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(url, forKey: .url)
    }
}

extension MoreLinksModel {
    static let deomJSON: [String: Any] = [
        "name": "Welcome Centre",
        "link": "https://www.uni-saarland.de/en/global/welcome-center.html"
    ]
}

extension MoreModel {
    static let demoData = MoreModel(
        linksLastChanged: "2020-01-20 17:42:14",
        links: [
            MoreLinksModel(displayName: "Welcome Centre", url: "https://www.uni-saarland.de/en/global/welcome-center.html", index: 0),
            MoreLinksModel(displayName: "AStA", url: "https://asta.uni-saarland.de/en/", index: 1),
            MoreLinksModel(displayName: "Busfahrplan", url: "https://www.saarfahrplan.de", index: 2),
            MoreLinksModel(displayName: "Hochschulsport", url: "https://www.uni-saarland.de/en/institution/sports.html", index: 3)
        ]
    )
}
