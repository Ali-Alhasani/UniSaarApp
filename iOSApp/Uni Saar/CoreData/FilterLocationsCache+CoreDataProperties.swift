//
//  FilterLocationsCache+CoreDataProperties.swift
//
//
//  Created by Ali Al-Hasani on 12/19/19.
//
//

import CoreData
import Foundation

public extension FilterLocationsCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FilterLocationsCache> {
        NSFetchRequest<FilterLocationsCache>(entityName: "FilterLocationsCache")
    }

    @NSManaged var locationID: String?
    @NSManaged var name: String?
}
