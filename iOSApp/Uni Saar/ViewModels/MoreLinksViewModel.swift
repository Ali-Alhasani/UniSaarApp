//
//  MoreLinksViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
import Observation

@Observable
class MoreLinksViewModel: ParentViewModel {
    var linksCells: [TableViewCellType<MoreLinksCellViewModel>] = []
    @ObservationIgnored lazy var fetchedResultsController: NSFetchedResultsController<MoreLinksCache> = {
        let fetchRequest = NSFetchRequest<MoreLinksCache>(entityName: String(describing: MoreLinksCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    let extraCells = [NSLocalizedString("AboutApp", comment: ""), NSLocalizedString("AppSettings", comment: "")]

    override init(dataClient: DataClient = DataClient()) {
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
            let links = try await dataClient.getMoreLinks()
            if links.links.count > 0 {
                linksCells = links.links.map { .normal(cellViewModel: $0) }
                AppSessionManager.shared.morelinksLastChanged = links.linksLastChanged
                dataClient.clearMoreLinksCache()
                dataClient.saveInCoreDataWith(model: links.links)
            }
            showLoadingIndicator = false
        } catch {
            showLoadingIndicator = false
            if AppSessionManager.shared.morelinksLastChanged == "never" {
                linksCells = [.error(message: error.localizedDescription)]
            }
            showError(error: error, tryAgainHandler: { [weak self] in
                self?.reloadGetApi()
            })
        }
    }

    func reloadGetApi() {
        Task { await self.loadGetMoreLinks() }
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
    var nameText: String {get }
}

extension MoreLinksModel: MoreLinksCellViewModel {
    var linkURL: URL? { return URL(string: url) }
    var nameText: String { return displayName }
}

extension MoreLinksCache: MoreLinksCellViewModel {
    var linkURL: URL? { return URL(string: link ?? "") }
    var nameText: String { return name ?? "" }
}
