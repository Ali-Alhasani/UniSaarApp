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
    var newsCells: [FeedItemState<NewsFeedCellViewModel>] = []
    var isPaginating: Bool = false
    var apiPageNumber = 0
    @ObservationIgnored var onInitialLoad: (@MainActor () -> Void)?
    let numberOfItemPerPage = 10
    var isFilterdCacheUpdated = false
    @ObservationIgnored lazy var fetchedResultsController:
        NSFetchedResultsController<NewsCategoriesCache> = {
            let fetchRequest = NSFetchRequest<NewsCategoriesCache>(
                entityName: String(describing: NewsCategoriesCache.self)
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(
                    key: #keyPath(FilterNoticesListCache.isSelected),
                    ascending: false
                )
            ]
            return NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataStack.sharedInstance
                    .persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        }()

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadFirstPage(filterCatgroies: [Int] = []) async {
        guard !showLoadingIndicator else { return }
        showLoadingIndicator = true
        apiPageNumber = 0
        var filterCatgroies = filterCatgroies
        if filterCatgroies.count == 0 {
            fetchNewsFilterFromStorage()
            filterCatgroies =
                fetchedResultsController.fetchedObjects?.filter {
                    !$0.isSelected
                }.compactMap { Int($0.categoryID) } ?? []
        }
        do {
            let news = try await dataClient.getNews(
                pageNumber: 0,
                numberOfItems: numberOfItemPerPage,
                filter: filterCatgroies
            )
            showLoadingIndicator = false
            guard news.newsItemCount > 0 else {
                newsCells = [.empty]
                return
            }
            isFilterdCacheUpdated = true
            if AppSessionManager.shared.newsFiltersLastChanged
                != news.categoriesLastChanged {
                AppSessionManager.shared.newsFiltersLastChanged =
                    news.categoriesLastChanged
                isFilterdCacheUpdated = false
            }
            newsCells = news.newsList.compactMap {
                .normal(cardViewModel: NewsFeedCellViewModel(newsItem: $0))
            }
            apiPageNumber += 1
            onInitialLoad?()
        } catch {
            showLoadingIndicator = false
            if newsCells.isEmpty {
                newsCells = [.error(message: error.localizedDescription)]
            }
            showError(error: error)
        }
    }

    func loadNextPage(filterCatgroies: [Int]) async {
        guard !isPaginating else { return }
        isPaginating = true
        var filterCatgroies = filterCatgroies
        if filterCatgroies.isEmpty {
            fetchNewsFilterFromStorage()
            filterCatgroies =
                fetchedResultsController.fetchedObjects?.filter {
                    !$0.isSelected
                }.compactMap { Int($0.categoryID) } ?? []
        }
        do {
            let news = try await dataClient.getNews(
                pageNumber: apiPageNumber,
                numberOfItems: numberOfItemPerPage,
                filter: filterCatgroies
            )
            isPaginating = false
            newsCells.append(
                contentsOf: news.newsList.compactMap {
                    .normal(cardViewModel: NewsFeedCellViewModel(newsItem: $0))
                }
            )
            apiPageNumber += 1
        } catch {
            isPaginating = false
            if newsCells.isEmpty {
                newsCells = [.error(message: error.localizedDescription)]
            }
            showError(error: error)
        }
    }

    func loadGetMockNews() {
        newsCells = NewsFeedModel.newsDemoData.newsList.compactMap {
            .normal(cardViewModel: NewsFeedCellViewModel(newsItem: $0))
        }
    }

    func fetchNewsFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("CoreData fetch failed: \(error)")
        }
    }
}

struct NewsFeedCellViewModel: Identifiable, Hashable {
    let newsItem: NewsModel

    var id: Int {
        newsItem.newsID
    }

    var titleText: String {
        newsItem.title
    }

    var subTitleText: String {
        newsItem.subTitle ?? ""
    }

    var imageURL: URL? {
        newsItem.imageURLString.flatMap(URL.init(string:))
    }

    var newsDate: String {
        newsItem.annoucementDate
    }

    var newsHeader: String {
        let categories = newsItem.categories.map(
            \.categoryName.strippingNoEventsSuffix
        ).joined(separator: ", ")
        return categories.isEmpty
            ? newsItem.annoucementDate
            : "\(newsItem.annoucementDate) | \(categories)"
    }

    var isEvent: Bool {
        newsItem.isEvent
    }
}

private extension String {
    var strippingNoEventsSuffix: String {
        let suffix = " (keine Veranstaltungen)"
        return hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}

extension NewsFeedCellViewModel {
    var newsItemURL: URLRequest? {
        let route: URLRouter =
            isEvent
                ? .eventDetail(newsItem.newsID) : .newsDetail(newsItem.newsID)
        return try? route.asURLRequest()
    }
}
