//
//  CacheClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation

@MainActor
final class CacheClient {
    static let shared = CacheClient()
    private init() {}

    private func createNoticesEntityFrom(model: FilterElement) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let noticesEntity = NSEntityDescription.insertNewObject(forEntityName: FilterCacheKeys.noticesEntityName, into: context) as? FilterNoticesListCache {
            noticesEntity.name = model.filterName
            noticesEntity.noticeID = model.filterID
            noticesEntity.isSelected = model.isSelected
            return noticesEntity
        }
        return nil
    }

    private func createLocationsEntityFrom(model: FilterElement) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let locationsEntity = NSEntityDescription.insertNewObject(forEntityName: FilterCacheKeys.locationsEntityName, into: context) as? FilterLocationsCache {
            locationsEntity.name = model.filterName
            locationsEntity.locationID = model.filterID
            return locationsEntity
        }
        return nil
    }

    private func createNewsCategoriesEntityFrom(model: FilterIntElement) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let locationsEntity = NSEntityDescription.insertNewObject(forEntityName: FilterCacheKeys.newsCategoriesEntityName, into: context) as? NewsCategoriesCache {
            locationsEntity.name = model.filterName
            locationsEntity.categoryID = Int32(model.filterID)
            locationsEntity.isSelected = model.isSelected
            return locationsEntity
        }
        return nil
    }

    private func createMoreLinksEntityFrom(model: MoreLinksModel) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let linksEntity = NSEntityDescription.insertNewObject(forEntityName: FilterCacheKeys.moreLinksEntityName, into: context) as? MoreLinksCache {
            linksEntity.name = model.displayName
            linksEntity.link = model.url
            linksEntity.orderIndex = Int16(model.index)
            return linksEntity
        }
        return nil
    }

    private func createHelpfulNumbersEntityFrom(model: NumberModel) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let helpfulNumbersEntity = NSEntityDescription.insertNewObject(forEntityName: FilterCacheKeys.helpfulNumberEntityName, into: context) as? HelpfulNumberCache {
            helpfulNumbersEntity.name = model.name
            helpfulNumbersEntity.link = model.link
            helpfulNumbersEntity.mail = model.mail
            helpfulNumbersEntity.number = model.number
            return helpfulNumbersEntity
        }
        return nil
    }

    func saveInCoreDataWith(model: FilterLocationCellViewModel) {
        _ = model.locationsText.map { self.createLocationsEntityFrom(model: $0) }
        _ = model.noticesText.map { self.createNoticesEntityFrom(model: $0) }
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }

    func saveInCoreDataWith(model: FilterCategoriesCellViewModel) {
        _ = model.categoriesText.map { self.createNewsCategoriesEntityFrom(model: $0) }
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }

    func saveInCoreDataWith(model: [MoreLinksModel]) {
        _ = model.map { self.createMoreLinksEntityFrom(model: $0) }
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }

    func saveInCoreDataWith(model: [NumberModel]) {
        _ = model.map { self.createHelpfulNumbersEntityFrom(model: $0) }
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }

    func clearFilterCache() {
        let managedObjectContext = CoreDataStack.sharedInstance.persistentContainer.viewContext
        let locationsfetchRequest = NSFetchRequest<FilterLocationsCache>(entityName: FilterCacheKeys.locationsEntityName)
        let noticesfetchRequest = NSFetchRequest<FilterNoticesListCache>(entityName: FilterCacheKeys.noticesEntityName)
        do {
            let locationsList = try managedObjectContext.fetch(locationsfetchRequest)
            _ = locationsList.map { managedObjectContext.delete($0) }
            CoreDataStack.sharedInstance.saveContext()
        } catch {
            print("ERROR DELETING : \(error)")
        }
        do {
            let noticesList = try managedObjectContext.fetch(noticesfetchRequest)
            _ = noticesList.map { managedObjectContext.delete($0) }
            CoreDataStack.sharedInstance.saveContext()
        } catch {
            print(error)
        }
    }

    func clearNewsCategoriesCache() {
        let managedObjectContext = CoreDataStack.sharedInstance.persistentContainer.viewContext
        let categoriesfetchRequest = NSFetchRequest<NewsCategoriesCache>(entityName: FilterCacheKeys.newsCategoriesEntityName)
        do {
            let categoriesList = try managedObjectContext.fetch(categoriesfetchRequest)
            _ = categoriesList.map { managedObjectContext.delete($0) }
            CoreDataStack.sharedInstance.saveContext()
        } catch {
            print("ERROR DELETING : \(error)")
        }
    }

    func clearMoreLinksCache() {
        let managedObjectContext = CoreDataStack.sharedInstance.persistentContainer.viewContext
        let moreLinksfetchRequest = NSFetchRequest<MoreLinksCache>(entityName: FilterCacheKeys.moreLinksEntityName)
        do {
            let linksList = try managedObjectContext.fetch(moreLinksfetchRequest)
            _ = linksList.map { managedObjectContext.delete($0) }
            CoreDataStack.sharedInstance.saveContext()
        } catch {
            print("ERROR DELETING : \(error)")
        }
    }

    func clearHelpfulNumbersCache() {
        let managedObjectContext = CoreDataStack.sharedInstance.persistentContainer.viewContext
        let helpfulNumberfetchRequest = NSFetchRequest<HelpfulNumberCache>(entityName: FilterCacheKeys.helpfulNumberEntityName)
        do {
            let helpfulNumberList = try managedObjectContext.fetch(helpfulNumberfetchRequest)
            _ = helpfulNumberList.map { managedObjectContext.delete($0) }
            CoreDataStack.sharedInstance.saveContext()
        } catch {
            print("ERROR DELETING : \(error)")
        }
    }
}
