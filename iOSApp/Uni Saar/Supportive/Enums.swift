//
//  enums.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
//custom print log messages
enum LogType {
    case all
    case error
    case note
    case none
    case testCase
    func printCase() -> String {
        switch self {
        case .all:
            return "Unknown :: "
        case .error:
            return "ERROR :: "
        case .note:
            return "NOTE :: "
        case .none:
            return ""
        case .testCase:
            return "TEST"
        }
    }
}
enum TableViewCellType<Model> {
    case normal(cellViewModel: Model)
    case error(message: String)
    case empty
}

enum Campus: String {
    case saarbruken = "sb"
    case homburg = "hom"
    var locationKey: String {
        return rawValue
    }
    var title: String {
        switch self {
        case .saarbruken:
            return "Saarbrücken"
        case .homburg:
            return "Homburg"
        }
    }
    var mapOverLayerImageName: String {
        switch self {
        case .saarbruken:
            return "saarbrucken"
        case .homburg:
            return "homburg"
        }
    }
    var mapCoorFileName: String {
        switch self {
        case .saarbruken:
            return "CampusSaarCoor"
        case .homburg:
            return "CampusHomCoor"
        }
    }

}
typealias FilterElement = (filterName: String, filterID: String, isSelected: Bool)
typealias FilterIntElement = (filterName: String, filterID: Int, isSelected: Bool)
