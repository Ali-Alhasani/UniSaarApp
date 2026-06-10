//
//  NewsFeedViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation
import Observation

@Observable
class NewsFeedViewModel: ParentViewModel {
    var newsCells: [TableViewCellType<NewsFeedCellViewModel>] = []
    var isFreshLoad: Bool = false
    var apiPageNumber = 0
    let numberOfItemPerPage = 10
    var isFilterdCacheUpdated = false
    @ObservationIgnored lazy var fetchedResultsController: NSFetchedResultsController<NewsCategoriesCache> = {
        let fetchRequest = NSFetchRequest<NewsCategoriesCache>(entityName: String(describing: NewsCategoriesCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.isSelected), ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }()

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetNews(_ isFirstTime: Bool = true, filterCatgroies: [Int]) async {
        showLoadingIndicator = true
        var filterCatgroies = filterCatgroies
        if filterCatgroies.count == 0 {
            fetchNewsFilterFromStorage()
            filterCatgroies = fetchedResultsController.fetchedObjects?.filter { !$0.isSelected }.compactMap { Int($0.categoryID) } ?? []
        }
        do {
            let news = try await dataClient.getNews(pageNumber: isFirstTime ? 0 : apiPageNumber, numberOfItems: numberOfItemPerPage, filter: filterCatgroies)
            showLoadingIndicator = false
            if isFirstTime {
                guard news.newsItemCount > 0 else {
                    newsCells = [.empty]
                    return
                }
                isFilterdCacheUpdated = true
                if AppSessionManager.shared.newsFiltersLastChanged != news.categoriesLastChanged {
                    AppSessionManager.shared.newsFiltersLastChanged = news.categoriesLastChanged
                    isFilterdCacheUpdated = false
                }
                newsCells = news.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel) }
                isFreshLoad = true
            } else {
                newsCells.append(contentsOf: news.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel) })
            }
            apiPageNumber += 1
        } catch {
            showLoadingIndicator = false
            newsCells = [.error(message: error.localizedDescription)]
            showError(error: error)
        }
    }

    func loadGetMockNews() {
        newsCells = NewsFeedModel.newsDemoData.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel) }
    }

    func fetchNewsFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}

protocol NewsFeedCellViewModel {
    var newsItem: NewsModel { get }
    var titleText: String { get }
    var subTitleText: String { get }
    var imageURL: URL? { get }
    var newsDate: String { get }
    var newsHeader: String { get }
    var isEvent: Bool { get }
}

extension NewsModel: NewsFeedCellViewModel {
    var newsItem: NewsModel {
        self
    }

    var titleText: String {
        title
    }

    var subTitleText: String {
        subTitle ?? ""
    }

    var imageURL: URL? {
        (imageURLString != nil) ? URL(string: imageURLString!) : nil
    }

    var newsDate: String {
        annoucementDate
    }

    var newsHeader: String {
        annoucementDate + " | " + categoryName.values.map(\.self).joined(separator: ", ")
    }
}
