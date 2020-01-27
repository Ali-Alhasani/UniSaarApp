//
//  MoreLinksCache+CoreDataProperties.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//
//

import Foundation
import CoreData

extension MoreLinksCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoreLinksCache> {
        return NSFetchRequest<MoreLinksCache>(entityName: "MoreLinksCache")
    }

    @NSManaged public var name: String?
    @NSManaged public var link: String?

}
