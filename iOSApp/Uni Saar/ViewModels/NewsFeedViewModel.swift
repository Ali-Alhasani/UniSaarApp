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
    // MARK: - Object Lifecycle
    let newsCells = Bindable([TableViewCellType<NewsFeedCellViewModel>]())
    var apiPageNumber = 0
    let numberOfItemPerPage = 10
    var isFilterdCacheUpdated = true
    // fetch news categories form coredata
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
        showLoadingIndicator.value = true
        var filterCatgroies = filterCatgroies
        // if the user open the screen for the first time, we load his cached filter
        if filterCatgroies.count == 0 {
            fetchNewsFilterFromStorage()
            filterCatgroies = fetchedResultsController.fetchedObjects?.filter {!$0.isSelected}.compactMap {Int($0.categoryID)} ?? []
        }
        dataClient.getNews(pageNumber: isFirstTime ? 0 : apiPageNumber, numberOfItems: numberOfItemPerPage, filter: filterCatgroies, completion: { [weak self] result in
            self?.showLoadingIndicator.value = false
            switch result {
            case .success(let news):
                if isFirstTime {
                    guard news.newsItemCount > 0 else {
                        self?.newsCells.value = [.empty]
                        return
                    }
                    self?.isFilterdCacheUpdated = true
                    if  AppSessionManager.shared.newsFiltersLastChanged != news.categoriesLastChanged {
                        AppSessionManager.shared.newsFiltersLastChanged = news.categoriesLastChanged
                        self?.isFilterdCacheUpdated = false
                    }
                    self?.newsCells.value = news.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel )}
                } else {
                    self?.newsCells.value.append(contentsOf: news.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel)})
                }
                self?.apiPageNumber += 1
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.newsCells.value = [.error(message: error?.localizedDescription ?? NSLocalizedString("UnknownError", comment: ""))]
                self?.showError(error: error)
            }
        })
    }
    func loadGetMockNews() {
        self.newsCells.value = NewsFeedModel.newsDemoData.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel)}
    }
    func fetchNewsFilterFromStorage() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
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
    // MARK: - Instance Properties
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
