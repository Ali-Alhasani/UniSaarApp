//
//  AboutAppModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

class AboutAppModel {
    var description: String
    var teamNames: [String]
    var contactNumber: String
    var contactEmail: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        description = jsonFromated["description"].stringValue
        teamNames = jsonFromated["teamNames"].arrayObject as? [String] ?? []
        contactNumber = jsonFromated["contactNumber"].stringValue
        contactEmail = jsonFromated["contactEmail"].stringValue
    }
}
