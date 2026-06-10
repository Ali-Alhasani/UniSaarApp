//
//  FilterNoticesListCache+CoreDataProperties.swift
//
//
//  Created by Ali Al-Hasani on 12/19/19.
//
//

import CoreData
import Foundation

public extension FilterNoticesListCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FilterNoticesListCache> {
        NSFetchRequest<FilterNoticesListCache>(entityName: "FilterNoticesListCache")
    }

    @NSManaged var noticeID: String?
    @NSManaged var name: String?
    @NSManaged var isAllergen: Bool
    @NSManaged var isNegated: Bool
    @NSManaged var isSelected: Bool
}
