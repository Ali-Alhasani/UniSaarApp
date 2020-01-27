//
//  NewsCategoriesCache+CoreDataProperties.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/20/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//
//

import Foundation
import CoreData

extension NewsCategoriesCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsCategoriesCache> {
        return NSFetchRequest<NewsCategoriesCache>(entityName: "NewsCategoriesCache")
    }

    @NSManaged public var categoryID: Int32
    @NSManaged public var isSelected: Bool
    @NSManaged public var name: String?

}
