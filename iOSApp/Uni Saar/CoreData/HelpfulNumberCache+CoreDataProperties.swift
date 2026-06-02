//
//  HelpfulNumberCache+CoreDataProperties.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//
//

import CoreData
import Foundation

public extension HelpfulNumberCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<HelpfulNumberCache> {
        NSFetchRequest<HelpfulNumberCache>(entityName: "HelpfulNumberCache")
    }

    @NSManaged var name: String?
    @NSManaged var number: String?
    @NSManaged var link: String?
    @NSManaged var mail: String?
}
