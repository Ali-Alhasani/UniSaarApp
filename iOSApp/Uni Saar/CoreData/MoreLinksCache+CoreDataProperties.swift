//
//  MoreLinksCache+CoreDataProperties.swift
//  
//
//  Created by Ali Al-Hasani on 7/27/20.
//
//

import Foundation
import CoreData

extension MoreLinksCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoreLinksCache> {
        return NSFetchRequest<MoreLinksCache>(entityName: "MoreLinksCache")
    }

    @NSManaged public var link: String?
    @NSManaged public var name: String?
    @NSManaged public var orderIndex: Int16

}
