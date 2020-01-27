//
//  MensaFilterList.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
class MensaFilterModel {
    var locations = [Locations]()
    var notices = [Notices]()
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.locations = jsonFromated["locations"].arrayValue.map {Locations(json: $0.dictionaryValue)}
        self.notices = jsonFromated["notices"].arrayValue.map {Notices(json: $0.dictionaryValue)}
    }
    init() {}
}
class Locations {
    var locationID: String
    var name: String
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.locationID = jsonFromated["locationID"].stringValue
        self.name = jsonFromated["name"].stringValue
    }
    init(locationID: String, name: String) {
        self.locationID = locationID
        self.name = name
    }
}
class Notices {
    var noticeID: String
    var name: String
    var isAllergen: Bool
    var isNegated: Bool
    init(json: [String: Any]) {
        let jsonFromated = JSON(json)
        self.noticeID = jsonFromated["noticeID"].stringValue
        self.name = jsonFromated["name"].stringValue
        self.isAllergen = jsonFromated["isAllergen"].boolValue
        self.isNegated = jsonFromated["isNegated"].boolValue
    }
    init(noticeID: String, name: String, isAllergen: Bool, isNegated: Bool) {
        self.noticeID = noticeID
        self.name = name
        self.isAllergen = isAllergen
        self.isNegated = isNegated
    }
}
//this just mock model to gives us a  clear perspective on the API design, by getting into the mindset of being a client of the API before it exists.
class FilterList {
    enum Filter: Int, CaseIterable {
        case location, dispalyAllergen, allergenList
    }
    private var mensaLocationsList: [ChecklistItem] = []
    private var emptyList: [ChecklistItem] = []
    private var isDispalyAllergen: Bool = true
    private var allergenList: [ChecklistItem] = []
    init() {
        let row0Item = ChecklistItem()
        let row1Item = ChecklistItem()
        let row2Item = ChecklistItem()
        let row3Item = ChecklistItem()
        let row4Item = ChecklistItem()
        let row5Item = ChecklistItem()
        let row6Item = ChecklistItem()
        let row7Item = ChecklistItem()
        let row8Item = ChecklistItem()
        let row9Item = ChecklistItem()
        let row10Item = ChecklistItem()
        let row11Item = ChecklistItem()
        let row12Item = ChecklistItem()
        let row13Item = ChecklistItem()
        let row20Item = ChecklistItem()
        row0Item.text = "Mensa/Mensacafé Saarbrücken"
        row1Item.text = "Mensa Homburg"
        row2Item.text = "Mensagarden"
        row3Item.text = "Cafeteria Hochschule für Musik Saar"
        row4Item.text = "Artificial colouring"
        row5Item.text = "Preservatives"
        row6Item.text = "Antioxidants"
        row7Item.text = "Flavour enhancer"
        row8Item.text = "Sulphurised"
        row9Item.text = "Blackened"
        row10Item.text = "Pork"
        row11Item.text = "Alcohol"
        row12Item.text = "Nuts"
        row13Item.text = "Without pork"
        row20Item.text = "Toggle all"
        mensaLocationsList = [row0Item, row1Item, row2Item, row3Item]
        emptyList = [row20Item]
        allergenList = [row4Item, row5Item, row6Item, row7Item, row8Item, row9Item, row10Item, row11Item, row12Item, row13Item]
    }
    func filterList(for fliter: Filter) -> [ChecklistItem] {
        switch fliter {
        case .location:
            return mensaLocationsList
        case .dispalyAllergen:
            return  emptyList
        case .allergenList:
            return allergenList
        }
    }
}

class ChecklistItem: NSObject {
    @objc var text = ""
    var checked = false
    func toggleChecked() {
        checked = !checked
    }
}
