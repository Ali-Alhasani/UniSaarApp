//
//  Cache.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/18/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation

@MainActor
class Cache {
    lazy var fetchedResultsController: NSFetchedResultsController<FilterNoticesListCache> = {
        let fetchRequest = NSFetchRequest<FilterNoticesListCache>(entityName: String(describing: FilterNoticesListCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.name), ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    lazy var fetchedLocationResultsController: NSFetchedResultsController<FilterLocationsCache> = {
        let fetchRequest = NSFetchRequest<FilterLocationsCache>(entityName: String(describing: FilterLocationsCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterLocationsCache.name), ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    static let shared = Cache()
    func fetchMensaFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
            try fetchedLocationResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}
