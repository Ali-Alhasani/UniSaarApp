//
//  NewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class NewsFeedViewController: UIViewController {
    @IBOutlet var newsTable: UITableView! {
        didSet {
            let refreshControl = newsTable.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(refershLoad), for: .valueChanged)
            newsTable.refreshControl = refreshControl
        }
    }

    lazy var newsViewModel: NewsFeedViewModel = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        Task { [weak self] in await self?.newsViewModel.loadGetNews(filterCatgroies: []) }
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if newsViewModel.showLoadingIndicator { newsTable.showingLoadingView() } else { newsTable.hideLoadingView() }
        if newsViewModel.isFreshLoad {
            Task { @MainActor [weak self] in
                guard let self else { return }
                newsViewModel.isFreshLoad = false
                initialSelection()
            }
        }
        if let alert = newsViewModel.currentAlert {
            Task { @MainActor [weak self] in
                guard let self else { return }
                newsViewModel.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }
        newsTable.reloadData()
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

    func initialSelection() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let initialIndexPath = IndexPath(row: 0, section: 0)
            switch newsViewModel.newsCells[safe: initialIndexPath.row] {
            case let .normal(viewModel):
                performSegue(withIdentifier: SegueIdentifiers.toNewsDetails, sender: viewModel)
                newsTable.selectRow(at: initialIndexPath, animated: true, scrollPosition: .none)
            case .empty, .error, .none:
                break
            }
        }
    }

    enum SegueIdentifiers {
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
        newsViewModel.newsCells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch newsViewModel.newsCells[safe: indexPath.row] {
        case let .normal(viewModel):
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
        case let .error(message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyNews", comment: ""))
        case .none:
            return defaultCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch newsViewModel.newsCells[safe: indexPath.row] {
        case let .normal(viewModel):
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

extension NewsFeedViewController: SingleButtonDialogPresenter {}

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
