//
//  FilterNewsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/20/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
class FilterNewsViewModel: ParentViewModel {
    // MARK: - Object Lifecycle
    let didUpdatefilterList: Bindable = Bindable(false)
    var isFilterdCacheUpdated: Bool = false
    lazy var fetchedResultsController: NSFetchedResultsController<NewsCategoriesCache> = {
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
    func loadGetFilterList() {
        showLoadingIndicator.value = true
        self.fetchNewsFilterFromStorage()
        if isFilterdCacheUpdated { // check if the filter date has not been updated from the server
            self.didUpdatefilterList.value = true
            self.showLoadingIndicator.value = false
        } else {
            dataClient.getNewsCategories(completion: { [weak self] result in
                self?.showLoadingIndicator.value = false
                switch result {
                case .success(let list):
                    guard let self = self  else {
                        return
                    }
                    let viewModelList = FilterCategoriesCellViewModel(newsFilterModel: list)
                    viewModelList.categoriesText = self.getOldSelectedCategories(newViewModel: viewModelList)
                    // remove last stored cache before saving the new data
                    self.dataClient.clearNewsCategoriesCache()
                    self.dataClient.saveInCoreDataWith(model: viewModelList)
                    self.fetchNewsFilterFromStorage()
                    self.isFilterdCacheUpdated = true
                    self.didUpdatefilterList.value = true
                case .failure(let error):
                    self?.showLoadingIndicator.value = false
                    self?.showError(error: error)
                }
            })
        }

    }

    func getOldSelectedCategories(newViewModel: FilterCategoriesCellViewModel) -> [FilterIntElement] {
        // get the last cached selected categories before update the new categories name or id
        let oldSelectedCategories = fetchedResultsController.fetchedObjects?.filter {!$0.isSelected}.map {$0.categoryID}
        //if there are no previous selected categories just return the updated list from the server as it
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
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
        }
    }
}
class FilterCategoriesCellViewModel {
    // MARK: - Instance Properties
    var categoriesText = [FilterIntElement]()
    var isFilterAll = true
    init(newsFilterModel: [NewsCategories]) {
        //inital value all filters are switch on
        categoriesText = newsFilterModel.compactMap {FilterIntElement(filterName: $0.categoryName, filterID: $0.categoryID, isSelected: true) }
    }
    init() {
    }
}
