//
//  NewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Observation

@MainActor
class NewsFeedViewController: UIViewController {
    @IBOutlet weak var newsTable: UITableView! {
        didSet {
            let refreshControl = newsTable.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
            newsTable.refreshControl = refreshControl
        }
    }
    lazy var newsViewModel: NewsFeedViewModel = NewsFeedViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        startObserving()
        Task { [weak self] in await self?.newsViewModel.loadGetNews(filterCatgroies: []) }
    }

    @objc private func refershLoad() {
        load(isFirstTime: true, filterCatgroies: [])
    }

    @objc func load(isFirstTime: Bool = true, filterCatgroies: [Int]) {
        Task { [weak self] in await self?.newsViewModel.loadGetNews(isFirstTime, filterCatgroies: filterCatgroies) }
    }

    func setupTableView() {
        newsTable.register(NewsFeedTableViewCell.nib, forCellReuseIdentifier: NewsFeedTableViewCell.identifier)
        newsTable.delegate = self
        newsTable.dataSource = self
        newsTable.layoutTableView()
    }

    private func startObserving() {
        withObservationTracking {
            _ = newsViewModel.newsCells
            _ = newsViewModel.isFreshLoad
            _ = newsViewModel.currentAlert
            newsTable.reloadData()
            newsViewModel.showLoadingIndicator ? newsTable.showingLoadingView() : newsTable.hideLoadingView()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if newsViewModel.isFreshLoad {
                    newsViewModel.isFreshLoad = false
                    initialSelection()
                }
                if let alert = newsViewModel.currentAlert {
                    newsViewModel.currentAlert = nil
                    presentSingleButtonDialog(alert: alert)
                }
                startObserving()
            }
        }
    }

    func initialSelection() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let initialIndexPath = IndexPath(row: 0, section: 0)
            switch newsViewModel.newsCells[safe: initialIndexPath.row] {
            case .normal(let viewModel):
                performSegue(withIdentifier: SegueIdentifiers.toNewsDetails, sender: viewModel)
                newsTable.selectRow(at: initialIndexPath, animated: true, scrollPosition: .none)
            case .empty, .error, .none:
                break
            }
        }
    }

    internal struct SegueIdentifiers {
        static let toNewsDetails = "toNewsReader"
        static let toEventDetails = "toEventsReader"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toNewsDetails,
           let destination = segue.destination as? UINavigationController,
           let destinationViewController = destination.topViewController as? NewsReaderViewController,
           let viewModel = sender as? NewsFeedCellViewModel {
            destinationViewController.newsItemViewModel = viewModel
        } else if let destination = segue.destination as? UINavigationController,
                  let destinationViewController = destination.topViewController as? FilterNewsFeedViewController {
            destinationViewController.delegate = self
            destinationViewController.filterNewsViewModel.isFilterdCacheUpdated = newsViewModel.isFilterdCacheUpdated
        }
    }
}

extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsViewModel.newsCells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch newsViewModel.newsCells[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.identifier, for: indexPath) as? NewsFeedTableViewCell else {
                return defaultCell
            }
            viewModel.configure(cell)
            if let imageURL = viewModel.imageURL {
                cell.newsImageView.af.setImage(withURL: imageURL, placeholderImage: UIImage(systemName: "arrow.2.circlepath.circle.fill"), completion: { response in
                    if response.response != nil {
                        self.newsTable.reloadRowAt()
                    }
                })
            }
            cell.selectionStyle = .none
            return cell
        case .error(let message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyNews", comment: ""))
        case .none:
            return defaultCell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch newsViewModel.newsCells[safe: indexPath.row] {
        case .normal(let viewModel):
            performSegue(withIdentifier: SegueIdentifiers.toNewsDetails, sender: viewModel)
        case .empty, .error, .none:
            break
        }
    }
}

extension NewsFeedViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        if maximumOffset - currentOffset <= 25.0 {
            load(isFirstTime: false, filterCatgroies: [])
        }
    }
}

extension NewsFeedViewController: SingleButtonDialogPresenter { }

extension NewsFeedViewController: FilterNewsFeedViewDelegate {
    func didSelectFilterAll() {
        load(filterCatgroies: [])
    }
    func scrollUp() {
        newsTable.scrollToTop(animated: true)
    }
    func didSelectCustomFiltering(newsCatgroies: [Int]) {
        scrollUp()
        load(filterCatgroies: newsCatgroies)
    }
}
