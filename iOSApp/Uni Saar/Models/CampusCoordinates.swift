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
class CampusCoordinatesModel {
    var mapInfo = [MapInfoModel]()
    init(data: Data) {
        do {
            let json = try JSON(data: data)
            let root = json["mapInfo"].arrayValue
            mapInfo = root.map { MapInfoModel(json: $0.dictionaryValue)}
        } catch {

        }
    }
}
class MapInfoModel {
    var campus: Campus?
    var name: String
    var function: String
    var longitude: String
    var latitude: String
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
        }
    }
}
