//
//  directoryViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
class DirectoryViewModel: ParentViewModel {
    // MARK: - Object Lifecycle
    let searchResutlsCells = Bindable([TableViewCellType<DirectorySearchResutlsCellViewModel>]())
    let helpfulNumbersCells = Bindable([TableViewCellType<HelpfulNumbersCellViewModel>]())
    lazy var fetchedResultsController: NSFetchedResultsController<HelpfulNumberCache> = {
        let fetchRequest = NSFetchRequest<HelpfulNumberCache>(entityName: String(describing: HelpfulNumberCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    var apiPageNumber = 0
    let numberOfItemPerPage = 10
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    func loadGetSearchResults(_ isFirstTime: Bool = true, searchQuery: String) {
        showLoadingIndicator.value = true
        dataClient.getSearchDirectory(pageNumber: isFirstTime ? 0 : apiPageNumber, numberOfItems: numberOfItemPerPage, query: searchQuery) { [weak self] result in
            self?.showLoadingIndicator.value = false
            switch result {
            case .success(let results):
                if isFirstTime {
                    guard results.staffItemCount > 0 else {
                        self?.searchResutlsCells.value = [.empty]
                        return
                    }
                    self?.searchResutlsCells.value = results.staffResults.compactMap { .normal(cellViewModel: $0 as DirectorySearchResutlsCellViewModel )}

                } else {
                    self?.searchResutlsCells.value.append(contentsOf: results.staffResults.compactMap { .normal(cellViewModel: $0 as DirectorySearchResutlsCellViewModel)})
                }
                self?.apiPageNumber += 1
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.searchResutlsCells.value = [.error(message: error?.localizedDescription ?? NSLocalizedString("UnknownError", comment: ""))]
                self?.showError(error: error)
            }
        }
    }
    func loadGetHelpHelpfulNumbers() {
        showLoadingIndicator.value = true
        if AppSessionManager.shared.helpfulNumbersLastChanged != "never" {
            fetchMoreLinksFromStorage()
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                self.helpfulNumbersCells.value = fetchedObjects.compactMap { .normal(cellViewModel: $0) }
            }
            self.showLoadingIndicator.value = false
        }

        dataClient.getDirectoryHelpfulNumbers { [weak self] result in
            switch result {
            case .success(let list):
                if list.numbers.count > 0 {
                    self?.helpfulNumbersCells.value = list.numbers.map { .normal(cellViewModel: $0) }
                    AppSessionManager.shared.helpfulNumbersLastChanged = list.numbersLastChanged
                    self?.dataClient.clearHelpfulNumbersCache()
                    self?.dataClient.saveInCoreDataWith(model: list.numbers)
                }
                self?.showLoadingIndicator.value = false
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                // we need to show the error message only if is the first time
                if AppSessionManager.shared.helpfulNumbersLastChanged == "never" {
                    self?.helpfulNumbersCells.value = [.error(message: error?.localizedDescription ?? NSLocalizedString("UnknownError", comment: ""))]
                }
                self?.showError(error: error)
            }
        }
    }
    func loadGetMockSearchResults() {
        //self?.searchResutlsCells.value = results.compactMap { .normal(cellViewModel: $0 as DirectorySearchResutlsCellViewModel )}
    }
    func fetchMoreLinksFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
        }
    }
}
protocol DirectorySearchResutlsCellViewModel {
    // MARK: - Instance Properties
    var titleText: String { get }
    var nameText: String { get }
    var staffId: Int { get }
}

protocol HelpfulNumbersCellViewModel {
    // MARK: - Instance Properties
    var fortmatedText: String { get }
}
extension StaffResultsModel: DirectorySearchResutlsCellViewModel {
    var titleText: String {
        return title
    }
    var nameText: String {
        return fullName
    }
    var staffId: Int {
        return staffID
    }
}

extension NumberModel: HelpfulNumbersCellViewModel {
    var fortmatedText: String {
        var finalText = ""
        if let name = name {
            finalText += name + "\n"
        }
        if let number = number {
            finalText += number + "\n"
        }
        if let link = link {
            finalText += link + "\n"
        }
        if let mail = mail {
            finalText += mail + "\n"
        }
        finalText.removeLast()
        return finalText
    }
}

extension HelpfulNumberCache: HelpfulNumbersCellViewModel {
    var fortmatedText: String {
        var finalText = ""
        if let name = name {
            finalText += name + "\n"
        }
        if let number = number {
            finalText += number + "\n"
        }
        if let link = link {
            finalText += link + "\n"
        }
        if let mail = mail {
            finalText += mail + "\n"
        }
        // remove the extra while speace
        finalText.removeLast()
        return finalText
    }
}
