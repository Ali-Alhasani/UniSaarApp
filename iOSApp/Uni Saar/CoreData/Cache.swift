//
//  Cache.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/18/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData

class Cache {

    lazy var fetchedResultsController: NSFetchedResultsController<FilterNoticesListCache> = {
        let fetchRequest = NSFetchRequest<FilterNoticesListCache>(entityName: String(describing: FilterNoticesListCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.isSelected), ascending: false)]
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

    class var shared: Cache {
        struct Static {
            static let instance = Cache()
        }
        return Static.instance
    }
    func fetchMensaFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
            try fetchedLocationResultsController.performFetch()
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
        }
    }
}
