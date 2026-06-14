//
//  MoreLinksViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation
import Observation

@Observable
class MoreLinksViewModel: ParentViewModel {
    var linksCells: [TableViewCellType<MoreLinksCellViewModel>] = []
    @ObservationIgnored lazy var fetchedResultsController: NSFetchedResultsController<MoreLinksCache> = {
        let fetchRequest = NSFetchRequest<MoreLinksCache>(entityName: String(describing: MoreLinksCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    let extraCells = [String(localized: "AboutApp"), String(localized: "AppSettings")]

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMoreLinks() async {
        showLoadingIndicator = true
        if AppSessionManager.shared.morelinksLastChanged != "never" {
            fetchMoreLinksFromStorage()
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                linksCells = fetchedObjects.compactMap { .normal(cellViewModel: $0) }
            }
            showLoadingIndicator = false
        }
        do {
            let links = try await dataClient.getMoreLinks(cacheLastChanged: AppSessionManager.shared.morelinksLastChanged)
            showLoadingIndicator = false
            if links.links.count > 0 {
                linksCells = links.links.map { .normal(cellViewModel: $0) }
                AppSessionManager.shared.morelinksLastChanged = links.linksLastChanged
                dataClient.clearMoreLinksCache()
                dataClient.saveInCoreDataWith(model: links.links)
            }
        } catch {
            showLoadingIndicator = false
            if AppSessionManager.shared.morelinksLastChanged == "never" {
                linksCells = [.error(message: error.localizedDescription)]
            }
            showError(error: error)
        }
    }

    func fetchMoreLinksFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}

protocol MoreLinksCellViewModel {
    var linkURL: URL? { get }
    var nameText: String { get }
}

extension MoreLinksModel: MoreLinksCellViewModel {
    var linkURL: URL? {
        URL(string: url)
    }

    var nameText: String {
        displayName
    }
}

extension MoreLinksCache: MoreLinksCellViewModel {
    var linkURL: URL? {
        URL(string: link ?? "")
    }

    var nameText: String {
        name ?? ""
    }
}
