//
//  FilterNewsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/20/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation
import Observation

@Observable
class FilterNewsViewModel: ParentViewModel {
    @ObservationIgnored var onFilterListUpdated: (@MainActor () -> Void)?
    var isFilterdCacheUpdated: Bool = false
    @ObservationIgnored var fetchedResultsController: NSFetchedResultsController<NewsCategoriesCache> = {
        let fetchRequest = NSFetchRequest<NewsCategoriesCache>(entityName: String(describing: NewsCategoriesCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.isSelected), ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    enum Filter: Int, CaseIterable {
        case location, allergenList
    }

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
        fetchNewsFilterFromStorage()
    }

    func loadGetFilterList() async {
        showLoadingIndicator = true
        fetchNewsFilterFromStorage()
        if isFilterdCacheUpdated {
            showLoadingIndicator = false
            onFilterListUpdated?()
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
            onFilterListUpdated?()
        } catch {
            showLoadingIndicator = false
            showError(error: error)
        }
    }

    func getOldSelectedCategories(newViewModel: FilterCategoriesCellViewModel) -> [FilterIntElement] {
        let oldSelectedCategories = fetchedResultsController.fetchedObjects?.filter { !$0.isSelected }.map(\.categoryID)
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
        categoriesText = newsFilterModel.compactMap { FilterIntElement(filterName: $0.categoryName, filterID: $0.categoryID, isSelected: true) }
    }

    init() {}
}
