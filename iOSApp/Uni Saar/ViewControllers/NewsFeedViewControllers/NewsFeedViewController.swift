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
    private let paginationSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: 0, height: 50)
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        Task { [weak self] in await self?.newsViewModel.loadFirstPage(filterCatgroies: []) }
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if newsViewModel.showLoadingIndicator { newsTable.showingLoadingView() } else { newsTable.hideLoadingView() }
        newsTable.tableFooterView = newsViewModel.isPaginating ? paginationSpinner : nil
        newsTable.reloadData()
    }

    @objc private func refershLoad() {
        Task { [weak self] in await self?.newsViewModel.loadFirstPage(filterCatgroies: []) }
    }

    private func setupViewModel() {
        newsViewModel.onAlert = { [weak self] alert in self?.presentSingleButtonDialog(alert: alert) }
        newsViewModel.onInitialLoad = { [weak self] in
            guard let self else { return }
            newsTable.reloadData()
            initialSelection()
        }
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
            cell.configure(with: viewModel)
            if let imageURL = viewModel.imageURL {
                cell.newsImageView.af.setImage(withURL: imageURL, placeholderImage: UIImage(systemName: "arrow.2.circlepath.circle.fill"), completion: { [weak self] response in
                    if response.response != nil {
                        self?.newsTable.reloadRowAt()
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
            Task { [weak self] in await self?.newsViewModel.loadNextPage(filterCatgroies: []) }
        }
    }
}

extension NewsFeedViewController: SingleButtonDialogPresenter {}

extension NewsFeedViewController: FilterNewsFeedViewDelegate {
    func didSelectFilterAll() {
        Task { [weak self] in await self?.newsViewModel.loadFirstPage(filterCatgroies: []) }
    }

    func scrollUp() {
        newsTable.scrollToTop(animated: true)
    }

    func didSelectCustomFiltering(newsCatgroies: [Int]) {
        scrollUp()
        Task { [weak self] in await self?.newsViewModel.loadFirstPage(filterCatgroies: newsCatgroies) }
    }
}
