//
//  MoreLinksCache+CoreDataProperties.swift
//
//
//  Created by Ali Al-Hasani on 7/27/20.
//
//

import CoreData
import Foundation

public extension MoreLinksCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MoreLinksCache> {
        NSFetchRequest<MoreLinksCache>(entityName: "MoreLinksCache")
    }

    @NSManaged var link: String?
    @NSManaged var name: String?
    @NSManaged var orderIndex: Int16
}
