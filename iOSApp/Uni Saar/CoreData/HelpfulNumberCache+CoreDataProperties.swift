//
//  HelpfulNumberCache+CoreDataProperties.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//
//

import Foundation
import CoreData

extension HelpfulNumberCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HelpfulNumberCache> {
        return NSFetchRequest<HelpfulNumberCache>(entityName: "HelpfulNumberCache")
    }

    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var link: String?
    @NSManaged public var mail: String?

}
