//
//  StaffModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

class StaffModel {
    var staffResults = [StaffResultsModel]()
    var staffItemCount: Int
    var hasNextPage: Bool
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        staffResults = jsonFromated["results"].arrayValue.map {StaffResultsModel(json: $0.dictionaryValue)}
        staffItemCount = jsonFromated["itemCount"].intValue
        hasNextPage = jsonFromated["hasNextPage"].boolValue
    }
}
class StaffResultsModel {
    var title: String
    var fullName: String
    var staffID: Int
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.title = jsonFromated["title"].stringValue
        self.staffID = jsonFromated["pid"].intValue
        self.fullName = jsonFromated["name"].stringValue
    }
}
class StaffDetailsModel {
    var email: String?
    var phoneNumber: String?
    var websiteURL: String?
    var gender: String?
    var title: String?
    var firstName: String?
    var lastName: String?
    var office: String?
    var building: String?
    var street: String?
    var postalCode: String?
    var city: String?
    var fax: String?
    var remarks: String?
    var image: String?
    var officeHour: String?

    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        firstName = jsonFromated["firstname"].string
        lastName = jsonFromated["lastname"].string
        title = jsonFromated["title"].string
        email = jsonFromated["mail"].string
        phoneNumber = jsonFromated["phone"].string
        gender = jsonFromated["gender"].string
        websiteURL = jsonFromated["webpage"].string
        office =  jsonFromated["office"].string
        building =  jsonFromated["building"].string
        street =  jsonFromated["street"].string
        postalCode =  jsonFromated["postalCode"].string
        city = jsonFromated["city"].string
        fax = jsonFromated["fax"].string
        remarks = jsonFromated["remark"].string
        image = jsonFromated["imageLink"].string
        officeHour = jsonFromated["officeHour"].string

    }
}
class StaffFavoritesModel: StaffModel {
    var isFavorited: Bool?
    override init(json: [String: Any]) {
        super.init(json: json)
    }
}
extension StaffModel {
    static let deomJSON: [String: Any] = ["name": "Ali Baylan", "title": "", "pid": 9091]
    static let staffDemoData = StaffModel(json: ["itemCount": 3, "results": [["name": "Ali Baylan", "title": "", "pid": 9091],
                                                             ["name": "Galina Baron", "title": "", "pid": 16776],
                                                             ["name": "Paanteha Kamali-Moghadam", "title": "M. Sc", "pid": 14477]]
        ]
    )
}
