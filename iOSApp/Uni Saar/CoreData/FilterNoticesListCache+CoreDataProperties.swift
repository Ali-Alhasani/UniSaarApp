//
//  FilterNoticesListCache+CoreDataProperties.swift
//  
//
//  Created by Ali Al-Hasani on 12/19/19.
//
//

import Foundation
import CoreData

extension FilterNoticesListCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FilterNoticesListCache> {
        return NSFetchRequest<FilterNoticesListCache>(entityName: "FilterNoticesListCache")
    }

    @NSManaged public var noticeID: String?
    @NSManaged public var name: String?
    @NSManaged public var isAllergen: Bool
    @NSManaged public var isNegated: Bool
    @NSManaged public var isSelected: Bool
}
