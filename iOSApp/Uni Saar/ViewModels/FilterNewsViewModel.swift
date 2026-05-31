//
//  FilterNewsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/20/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
import Observation

@Observable
class FilterNewsViewModel: ParentViewModel {
    var didUpdatefilterList: Bool = false
    var isFilterdCacheUpdated: Bool = false
    @ObservationIgnored var fetchedResultsController: NSFetchedResultsController<NewsCategoriesCache> = {
        let fetchRequest = NSFetchRequest<NewsCategoriesCache>(entityName: String(describing: NewsCategoriesCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.isSelected), ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()

    enum Filter: Int, CaseIterable {
        case location, allergenList
    }

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetFilterList() async {
        showLoadingIndicator = true
        fetchNewsFilterFromStorage()
        if isFilterdCacheUpdated {
            didUpdatefilterList = true
            showLoadingIndicator = false
            return
        }
        do {
            let list = try await dataClient.getNewsCategories()
            showLoadingIndicator = false
            let viewModelList = FilterCategoriesCellViewModel(newsFilterModel: list)
            viewModelList.categoriesText = getOldSelectedCategories(newViewModel: viewModelList)
            dataClient.clearNewsCategoriesCache()
            dataClient.saveInCoreDataWith(model: viewModelList)
            fetchNewsFilterFromStorage()
            isFilterdCacheUpdated = true
            didUpdatefilterList = true
        } catch {
            showLoadingIndicator = false
            didUpdatefilterList = false
            showError(error: error, tryAgainHandler: { [weak self] in
                self?.reloadGetApi()
            })
        }
    }

    func reloadGetApi() {
        Task { await self.loadGetFilterList() }
    }

    func getOldSelectedCategories(newViewModel: FilterCategoriesCellViewModel) -> [FilterIntElement] {
        let oldSelectedCategories = fetchedResultsController.fetchedObjects?.filter {!$0.isSelected}.map {$0.categoryID}
        guard let selectedCategories = oldSelectedCategories, selectedCategories.count > 0 else {
            return newViewModel.categoriesText
        }
        var intersectionCategories = [FilterIntElement]()
        for category in newViewModel.categoriesText {
            if selectedCategories.contains(Int32(category.filterID)) {
                intersectionCategories.append((filterName: category.filterName, filterID: category.filterID, isSelected: false))
            } else {
                intersectionCategories.append(category)
            }
        }
        return intersectionCategories
    }

    func fetchNewsFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}

class FilterCategoriesCellViewModel {
    var categoriesText = [FilterIntElement]()
    var isFilterAll = true
    init(newsFilterModel: [NewsCategories]) {
        categoriesText = newsFilterModel.compactMap {FilterIntElement(filterName: $0.categoryName, filterID: $0.categoryID, isSelected: true) }
    }
    init() { }
}
