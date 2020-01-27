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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
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
                self.linksCells.value = fetchedObjects.compactMap { .normal(cellViewModel: $0) }
            }
            self.showLoadingIndicator.value = false
        }

        dataClient.getMoreLinks { [weak self] result in
            self?.showLoadingIndicator.value = false
            switch result {
            case .success(let links):
                if links.links.count > 0 {
                    self?.linksCells.value = links.links.map { .normal(cellViewModel: $0) }
                    AppSessionManager.shared.morelinksLastChanged = links.linksLastChanged
                    self?.dataClient.clearMoreLinksCache()
                    self?.dataClient.saveInCoreDataWith(model: links.links)
                }
                self?.showLoadingIndicator.value = false
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                // we need to show the error message only if is the first time
                if AppSessionManager.shared.morelinksLastChanged == "never" {
                self?.linksCells.value = [.error(message: error?.localizedDescription ?? "Loading failed, check network connection")]
                }
                self?.showError(error: error)
            }
        }
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
