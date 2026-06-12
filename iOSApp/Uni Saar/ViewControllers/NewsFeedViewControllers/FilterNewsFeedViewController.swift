//
//  FilterNewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
protocol FilterNewsFeedViewDelegate: AnyObject {
    func didSelectFilterAll()
    func didSelectCustomFiltering(newsCatgroies: [Int])
}

@MainActor
class FilterNewsFeedViewController: UIViewController {
    @IBOutlet var filterTableView: UITableView! {
        didSet {
            let refreshControl = filterTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(refershLoad), for: .valueChanged)
            filterTableView.refreshControl = refreshControl
        }
    }

    lazy var filterNewsViewModel: FilterNewsViewModel = .init()
    weak var delegate: FilterNewsFeedViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        filterNewsViewModel.onAlert = { [weak self] alert in self?.presentSingleButtonDialog(alert: alert) }
        filterNewsViewModel.onFilterListUpdated = { [weak self] in self?.filterTableView.reloadData() }
        Task { [weak self] in await self?.filterNewsViewModel.loadGetFilterList() }
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if filterNewsViewModel.showLoadingIndicator { filterTableView.showingLoadingView() } else { filterTableView.hideLoadingView() }
    }

    func setupTableView() {
        filterTableView.register(FilterUISwitchTableViewCell.nib, forCellReuseIdentifier: FilterUISwitchTableViewCell.identifier)
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.layoutTableView()
        filterTableView.rowHeight = UITableView.automaticDimension
        filterTableView.allowsSelection = false
        view.backgroundColor = UIColor.flatGray
    }

    @objc private func refershLoad() {
        filterNewsViewModel.isFilterdCacheUpdated = false
        Task { [weak self] in await self?.filterNewsViewModel.loadGetFilterList() }
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        dismissView()
        let custumFiltitedCategories = filterNewsViewModel.fetchedResultsController.fetchedObjects?.compactMap(\.self).filter { !$0.isSelected }
        if let custumFiltitedCategories {
            let filtitedCategoriesId = custumFiltitedCategories.compactMap { Int($0.categoryID) }
            delegate?.didSelectCustomFiltering(newsCatgroies: filtitedCategoriesId)
        }
    }

    func dismissView() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension FilterNewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterNewsViewModel.fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as? FilterUISwitchTableViewCell
        if let item = filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: indexPath.row] {
            cell?.cellTitle = item.name
            cell?.delegate = self
            cell?.indexPath = indexPath
            cell?.switchValue = item.isSelected
        }
        return cell ?? UITableViewCell()
    }
}

extension FilterNewsFeedViewController: SingleButtonDialogPresenter {}

// MARK: - NewsFilterViewCellDelegate

extension FilterNewsFeedViewController: NewsFilterViewCellDelegate {
    func didSwitchOnFilter(indexPath: IndexPath?) {
        if let indexPath {
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = true
            }
        }
    }

    func didSwitchOffFilter(indexPath: IndexPath?) {
        if let indexPath {
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = false
            }
        }
    }
}
