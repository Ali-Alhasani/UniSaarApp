//
//  NewsCategoriesCache+CoreDataProperties.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/20/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//
//

import CoreData
import Foundation

public extension NewsCategoriesCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<NewsCategoriesCache> {
        NSFetchRequest<NewsCategoriesCache>(entityName: "NewsCategoriesCache")
    }

    @NSManaged var categoryID: Int32
    @NSManaged var isSelected: Bool
    @NSManaged var name: String?
}
