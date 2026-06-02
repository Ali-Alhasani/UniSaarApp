//
//  DirectoryViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation
import Observation
import UIKit

@Observable
class DirectoryViewModel: ParentViewModel {
    var searchResutlsCells: [TableViewCellType<DirectorySearchResutlsCellViewModel>] = []
    var helpfulNumbersCells: [TableViewCellType<HelpfulNumbersCellViewModel>] = []
    @ObservationIgnored lazy var fetchedResultsController: NSFetchedResultsController<HelpfulNumberCache> = {
        let fetchRequest = NSFetchRequest<HelpfulNumberCache>(entityName: String(describing: HelpfulNumberCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    var apiPageNumber = 0
    let numberOfItemPerPage = UIDevice.current.userInterfaceIdiom == .pad ? 16 : 10
    var hasNextPage = false

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetSearchResults(_ isFirstTime: Bool = true, searchQuery: String) async {
        if !hasNextPage, isFirstTime == false {
            return
        }
        showLoadingIndicator = true
        do {
            let results = try await dataClient.getSearchDirectory(pageNumber: isFirstTime ? 0 : apiPageNumber, numberOfItems: numberOfItemPerPage, query: searchQuery)
            showLoadingIndicator = false
            if isFirstTime {
                guard results.staffItemCount > 0 else {
                    searchResutlsCells = [.empty]
                    return
                }
                searchResutlsCells = results.staffResults.compactMap { .normal(cellViewModel: $0 as DirectorySearchResutlsCellViewModel) }
                apiPageNumber = 0
            } else {
                searchResutlsCells.append(contentsOf: results.staffResults.compactMap { .normal(cellViewModel: $0 as DirectorySearchResutlsCellViewModel) })
            }
            hasNextPage = results.hasNextPage
            apiPageNumber += 1
        } catch {
            showLoadingIndicator = false
            searchResutlsCells = [.error(message: error.localizedDescription)]
            if !(error is LLError) {
                showError(error: error)
            }
        }
    }

    func loadGetHelpHelpfulNumbers() async {
        showLoadingIndicator = true
        if AppSessionManager.shared.helpfulNumbersLastChanged != "never" {
            fetchMoreLinksFromStorage()
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                helpfulNumbersCells = fetchedObjects.compactMap { .normal(cellViewModel: $0) }
            }
            showLoadingIndicator = false
        }
        do {
            let list = try await dataClient.getDirectoryHelpfulNumbers(cacheLastChanged: AppSessionManager.shared.helpfulNumbersLastChanged)
            if list.numbers.count > 0 {
                helpfulNumbersCells = list.numbers.map { .normal(cellViewModel: $0) }
                AppSessionManager.shared.helpfulNumbersLastChanged = list.numbersLastChanged
                dataClient.clearHelpfulNumbersCache()
                dataClient.saveInCoreDataWith(model: list.numbers)
            }
            showLoadingIndicator = false
        } catch {
            showLoadingIndicator = false
            if AppSessionManager.shared.helpfulNumbersLastChanged == "never" {
                helpfulNumbersCells = [.error(message: error.localizedDescription)]
            }
            showError(error: error, tryAgainHandler: { [weak self] in
                self?.reloadGetApi()
            })
        }
    }

    func reloadGetApi() {
        Task { await self.loadGetHelpHelpfulNumbers() }
    }

    func loadGetMockSearchResults() {}

    func fetchMoreLinksFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}

protocol DirectorySearchResutlsCellViewModel {
    var titleText: String { get }
    var nameText: String { get }
    var staffId: Int { get }
}

protocol HelpfulNumbersCellViewModel {
    var fortmatedText: String { get }
}

extension StaffResultsModel: DirectorySearchResutlsCellViewModel {
    var titleText: String {
        title
    }

    var nameText: String {
        fullName
    }

    var staffId: Int {
        staffID
    }
}

extension NumberModel: HelpfulNumbersCellViewModel {
    var fortmatedText: String {
        var finalText = ""
        if let name { finalText += name + "\n" }
        if let number { finalText += number + "\n" }
        if let link { finalText += link + "\n" }
        if let mail { finalText += mail + "\n" }
        finalText.removeLast()
        return finalText
    }
}

extension HelpfulNumberCache: HelpfulNumbersCellViewModel {
    var fortmatedText: String {
        var finalText = ""
        if let name { finalText += name + "\n" }
        if let number { finalText += number + "\n" }
        if let link { finalText += link + "\n" }
        if let mail { finalText += mail + "\n" }
        finalText.removeLast()
        return finalText
    }
}
