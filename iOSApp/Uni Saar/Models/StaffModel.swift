//
//  StaffModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

final class StaffModel: Sendable {
    let staffResults: [StaffResultsModel]
    let staffItemCount: Int
    let hasNextPage: Bool
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        staffResults = jsonFromated["results"].arrayValue.map { StaffResultsModel(json: $0.dictionaryValue) }
        staffItemCount = jsonFromated["itemCount"].intValue
        hasNextPage = jsonFromated["hasNextPage"].boolValue
    }
}

final class StaffResultsModel: Sendable {
    let title: String
    let fullName: String
    let staffID: Int
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        title = jsonFromated["title"].stringValue
        staffID = jsonFromated["pid"].intValue
        fullName = jsonFromated["name"].stringValue
    }
}

final class StaffDetailsModel: Sendable {
    let email: String?
    let phoneNumber: String?
    let websiteURL: String?
    let gender: String?
    let title: String?
    let firstName: String?
    let lastName: String?
    let office: String?
    let building: String?
    let street: String?
    let postalCode: String?
    let city: String?
    let fax: String?
    let remarks: String?
    let image: String?
    let officeHour: String?

    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        firstName = jsonFromated["firstname"].string
        lastName = jsonFromated["lastname"].string
        title = jsonFromated["title"].string
        email = jsonFromated["mail"].string
        phoneNumber = jsonFromated["phone"].string
        gender = jsonFromated["gender"].string
        websiteURL = jsonFromated["webpage"].string
        office = jsonFromated["office"].string
        building = jsonFromated["building"].string
        street = jsonFromated["street"].string
        postalCode = jsonFromated["postalCode"].string
        city = jsonFromated["city"].string
        fax = jsonFromated["fax"].string
        remarks = jsonFromated["remark"].string
        image = jsonFromated["imageLink"].string
        officeHour = jsonFromated["officeHour"].string
    }
}

final class StaffFavoritesModel: @unchecked Sendable {
    let staffResults: [StaffResultsModel]
    let staffItemCount: Int
    let hasNextPage: Bool
    var isFavorited: Bool?
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        staffResults = jsonFromated["results"].arrayValue.map { StaffResultsModel(json: $0.dictionaryValue) }
        staffItemCount = jsonFromated["itemCount"].intValue
        hasNextPage = jsonFromated["hasNextPage"].boolValue
    }
}

extension StaffModel {
    // nonisolated(unsafe) is required when the type is not Sendable (e.g. [String: Any] — because Any isn't Sendable).
    // Sendable types (like StaffModel) don't need it; Swift verifies safety on its own.
    nonisolated(unsafe) static let deomJSON: [String: Any] = ["name": "Ali Baylan", "title": "", "pid": 9091]
    static let staffDemoData = StaffModel(json: ["itemCount": 3, "results": [["name": "Ali Baylan", "title": "", "pid": 9091],
                                                                             ["name": "Galina Baron", "title": "", "pid": 16776],
                                                                             ["name": "Paanteha Kamali-Moghadam", "title": "M. Sc", "pid": 14477]]])
}
