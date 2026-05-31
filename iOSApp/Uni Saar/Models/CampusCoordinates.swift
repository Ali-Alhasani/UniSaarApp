//
//  CampusCoordinates.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/16/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

public func dataFromFile(_ filename: String) -> Data? {
    let bundle = Bundle(for: CampusCoordinatesModel.self)
    if let path = bundle.path(forResource: filename, ofType: "json") {
        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
    return nil
}

final class CampusCoordinatesModel {
    let mapInfo: [MapInfoModel]
    let updateTime: String
    init(data: Data) {
        do {
            let json = try JSON(data: data)
            let root = json["mapInfo"].arrayValue
            updateTime = json["updateTime"].stringValue
            mapInfo = root.map { MapInfoModel(json: $0.dictionaryValue)}
        } catch {
            updateTime = ""
            mapInfo = []
        }
    }

    init(json: JSON) {
        let root = json["mapInfo"].arrayValue
        updateTime = json["updateTime"].stringValue
        mapInfo = root.map { MapInfoModel(json: $0.dictionaryValue)}
    }
}

final class CoordinatesCacheModel {
    let mapInfo: JSON
    let updateTime: String
    init(json: JSON) {
        mapInfo = json
        updateTime = json["updateTime"].stringValue
    }
}

final class MapInfoModel {
    let campus: Campus?
    let name: String
    let function: String
    let longitude: String
    let latitude: String
    init(json: [String: Any]) {
        let formattedJson = JSON(json)
        name = formattedJson["name"].stringValue
        function = formattedJson["function"].stringValue
        longitude = formattedJson["longitude"].stringValue
        latitude = formattedJson["latitude"].stringValue
        let campusString = formattedJson["campus"].stringValue
        if campusString == "saar" {
            campus = Campus.saarbruken
        } else if campusString == "hom" {
            campus = Campus.homburg
        } else {
            campus = nil
        }
    }
}
