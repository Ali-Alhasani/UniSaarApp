//
//  NewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class NewsFeedViewController: UIViewController {
    @IBOutlet weak var newsTable: UITableView! {
        didSet {
            DispatchQueue.main.async {
                let refreshControl = self.newsTable.setUpRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
                self.newsTable.refreshControl = refreshControl
            }
        }
    }
    // MARK: - Instance Properties
    lazy var newsViewModel: NewsFeedViewModel = NewsFeedViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
        bindViewModel()
        newsViewModel.loadGetNews(filterCatgroies: [])
        //just a test mock function without server calling
        //newsViewModel.loadGetMockNews()
    }
    @objc private func refershLoad() {
        self.load(isFirstTime: true, filterCatgroies: [])
    }
    @objc func load(isFirstTime: Bool = true, filterCatgroies: [Int]) {
        newsViewModel.loadGetNews(isFirstTime, filterCatgroies: filterCatgroies)
    }
    func setupTableView() {
        newsTable.register(NewsFeedTableViewCell.nib, forCellReuseIdentifier: NewsFeedTableViewCell.identifier)
        newsTable.delegate = self
        newsTable.dataSource = self
        newsTable.layoutTableView()
    }
    func bindViewModel() {
        newsViewModel.newsCells.bind { [weak self] _ in
            if let `self` = self {
                self.newsTable.reloadData()
            }
        }
        newsViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        newsViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.newsTable.showingLoadingView() : self.newsTable.hideLoadingView()
            }
        }
    }
    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toNewsDetails = "toNewsReader"
        static let toEventDetails = "toEventsReader"
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueIdentifiers.toNewsDetails, let destination = segue.destination as? UINavigationController,
            let destinationViewController = destination.topViewController as? NewsReaderViewController,
            let viewModel = sender as? NewsFeedCellViewModel {
            destinationViewController.newsItemViewModel = viewModel
        } else if let destination = segue.destination as? UINavigationController, let destinationViewController = destination.topViewController as? FilterNewsFeedViewController {
            destinationViewController.delegate = self
            destinationViewController.filterNewsViewModel.isFilterdCacheUpdated = newsViewModel.isFilterdCacheUpdated
        }
    }
}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsViewModel.newsCells.value.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch newsViewModel.newsCells.value[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.identifier, for: indexPath) as? NewsFeedTableViewCell else {
                return defaultCell
            }
            viewModel.configure(cell)
            if let imageURL = viewModel.imageURL {
                // async download
                cell.newsImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "SF_arrow_2_circlepath_circle_fill")) { response in
                    // Check if the image isn't already cached
                    if response.response != nil {
                        // Force the cell update
                        self.newsTable.reloadRowAt()
                    }
                }
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
        switch newsViewModel.newsCells.value[safe: indexPath.row] {
        case .normal(let viewModel):
            self.performSegue(withIdentifier: SegueIdentifiers.toNewsDetails, sender: viewModel)
        case .empty, .error, .none:
            // nop no click action should be done for empty cell's
            break
        }
    }
}
// load more news if the user reach the bottom of the screen
extension NewsFeedViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        // the distance from bottom
        if maximumOffset - currentOffset <= 25.0 {
            self.load(isFirstTime: false, filterCatgroies: [])
        }
    }
}
extension NewsFeedViewController: SingleButtonDialogPresenter { }
// MARK: - FilterNewsFeedViewDelegate
extension NewsFeedViewController: FilterNewsFeedViewDelegate {
    func didSelectFilterAll() {
        load(filterCatgroies: [])
    }

    func scrollUp() {
        DispatchQueue.main.async {
            self.newsTable.scrollToTop(animated: true)
        }
    }
    func didSelectCustomFiltering(newsCatgroies: [Int]) {
        scrollUp()
        load(filterCatgroies: newsCatgroies)
    }
}
