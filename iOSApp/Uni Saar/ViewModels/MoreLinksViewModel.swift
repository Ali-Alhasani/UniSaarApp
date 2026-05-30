//
//  MoreLinksViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
class MoreLinksViewModel: ParentViewModel {
    let linksCells = Bindable([TableViewCellType<MoreLinksCellViewModel>]())
    lazy var fetchedResultsController: NSFetchedResultsController<MoreLinksCache> = {
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

    func loadGetMoreLinks() {
        showLoadingIndicator.value = true
        if AppSessionManager.shared.morelinksLastChanged != "never" {
            fetchMoreLinksFromStorage()
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                linksCells.value = fetchedObjects.compactMap { .normal(cellViewModel: $0) }
            }
            showLoadingIndicator.value = false
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let links = try await dataClient.getMoreLinks()
                if links.links.count > 0 {
                    linksCells.value = links.links.map { .normal(cellViewModel: $0) }
                    AppSessionManager.shared.morelinksLastChanged = links.linksLastChanged
                    dataClient.clearMoreLinksCache()
                    dataClient.saveInCoreDataWith(model: links.links)
                }
                showLoadingIndicator.value = false
            } catch {
                showLoadingIndicator.value = false
                if AppSessionManager.shared.morelinksLastChanged == "never" {
                    linksCells.value = [.error(message: error.localizedDescription)]
                }
                showError(error: error, tryAgainHandler: { [weak self] in
                    self?.reloadGetApi()
                })
            }
        }
    }

    func reloadGetApi() {
        loadGetMoreLinks()
    }
    func fetchMoreLinksFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
        }
    }

}

protocol MoreLinksCellViewModel {
    // MARK: - Instance Properties
    var linkURL: URL? { get }
    var nameText: String {get }
}

extension MoreLinksModel: MoreLinksCellViewModel {
    var linkURL: URL? {
        return URL(string: url)
    }

    var nameText: String {
        return displayName
    }
}
extension MoreLinksCache: MoreLinksCellViewModel {
    var linkURL: URL? {
        return URL(string: link ?? "")
    }

    var nameText: String {
        return name ?? ""
    }
}
