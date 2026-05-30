//
//  NewsFeedViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
import AlamofireImage
import CoreData

class NewsFeedViewModel: ParentViewModel {
    @Published var newsCells: [TableViewCellType<NewsFeedCellViewModel>] = []
    @Published var isFreshLoad: Bool = true
    var apiPageNumber = 0
    let numberOfItemPerPage = 10
    var isFilterdCacheUpdated = false
    lazy var fetchedResultsController: NSFetchedResultsController<NewsCategoriesCache> = {
        let fetchRequest = NSFetchRequest<NewsCategoriesCache>(entityName: String(describing: NewsCategoriesCache.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FilterNoticesListCache.isSelected), ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetNews(_ isFirstTime: Bool = true, filterCatgroies: [Int]) {
        showLoadingIndicator = true
        var filterCatgroies = filterCatgroies
        if filterCatgroies.count == 0 {
            fetchNewsFilterFromStorage()
            filterCatgroies = fetchedResultsController.fetchedObjects?.filter {!$0.isSelected}.compactMap {Int($0.categoryID)} ?? []
        }
        Task { [weak self] in
            guard let self else { return }
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

@objc public protocol NewsFeedViewModelView {
    @objc var titleLabel: UILabel? { get }
    @objc optional var subTitleLabel: UILabel? { get }
    @objc optional var dateLabel: UILabel? { get }
    @objc optional var newsImage: UIImageView? { get}
}

protocol NewsFeedCellViewModel {
    var newsItem: NewsModel { get }
    var titleText: String { get }
    var subTitleText: String { get }
    var imageURL: URL? { get }
    var newsDate: String {get }
    var newsHeader: String { get }
    var isEvent: Bool { get }
}

extension NewsModel: NewsFeedCellViewModel {
    var newsItem: NewsModel {
        return self
    }
    var titleText: String {
        return title
    }
    var subTitleText: String {
        return subTitle ?? ""
    }
    var imageURL: URL? {
        return (imageURLString != nil) ? URL(string: imageURLString!) : nil
    }
    var newsDate: String {
        return annoucementDate
    }
    var newsHeader: String {
        return annoucementDate + " | " + categoryName.values.map {$0}.joined(separator: ", ")
    }
}

extension NewsFeedCellViewModel {
    public func configure(_ view: NewsFeedViewModelView) {
        view.titleLabel?.text = titleText
        view.subTitleLabel??.text = subTitleText
        view.dateLabel??.text = newsHeader
    }
}
