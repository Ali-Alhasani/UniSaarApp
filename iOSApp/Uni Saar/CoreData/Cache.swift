//
//  Cache.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/18/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData

@MainActor
class Cache {

    lazy var fetchedResultsController: NSFetchedResultsController<FilterNoticesListCache> = {
        let fetchRequest = NSFetchRequest<FilterNoticesListCache>(entityName: String(describing: FilterNoticesListCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.name), ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()

    lazy var fetchedLocationResultsController: NSFetchedResultsController<FilterLocationsCache> = {
        let fetchRequest = NSFetchRequest<FilterLocationsCache>(entityName: String(describing: FilterLocationsCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterLocationsCache.name), ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
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
