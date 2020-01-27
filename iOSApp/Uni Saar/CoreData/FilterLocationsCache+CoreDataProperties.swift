//
//  FilterLocationsCache+CoreDataProperties.swift
//  
//
//  Created by Ali Al-Hasani on 12/19/19.
//
//

import Foundation
import CoreData

extension FilterLocationsCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FilterLocationsCache> {
        return NSFetchRequest<FilterLocationsCache>(entityName: "FilterLocationsCache")
    }

    @NSManaged public var locationID: String?
    @NSManaged public var name: String?

}
