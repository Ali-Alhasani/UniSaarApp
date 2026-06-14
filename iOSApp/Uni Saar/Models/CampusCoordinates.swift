//
//  CampusCoordinates.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/16/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct CampusCoordinatesModel: Codable, Sendable, Equatable {
    let updateTime: String
    let mapInfo: [MapInfoModel]
}

extension CampusCoordinatesModel {
    enum CodingKeys: String, CodingKey { case updateTime, mapInfo }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            updateTime: container.value(.updateTime, default: ""),
            mapInfo:    container.value(.mapInfo,    default: [])
        )
    }

    init(data: Data) {
        self = (try? JSONDecoder.unisaarDefault.decode(Self.self, from: data)) ?? CampusCoordinatesModel(updateTime: "", mapInfo: [])
    }
}

struct MapInfoModel: Sendable, Equatable, Hashable {
    let campus: Campus?
    let name: String
    let function: String
    let longitude: String
    let latitude: String
}

extension MapInfoModel: Codable {
    enum CodingKeys: String, CodingKey {
        case campus, name, function, longitude, latitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let campusString: String = try container.value(.campus, default: "")
        switch campusString {
        case "saar": campus = .saarbruken
        case "hom":  campus = .homburg
        default:     campus = nil
        }
        name      = try container.value(.name,      default: "")
        function  = try container.value(.function,  default: "")
        longitude = try container.value(.longitude, default: "")
        latitude  = try container.value(.latitude,  default: "")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch campus {
        case .saarbruken: try container.encode("saar", forKey: .campus)
        case .homburg:    try container.encode("hom",  forKey: .campus)
        case .none:       try container.encode("",     forKey: .campus)
        }
        try container.encode(name,      forKey: .name)
        try container.encode(function,  forKey: .function)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude,  forKey: .latitude)
    }
}
