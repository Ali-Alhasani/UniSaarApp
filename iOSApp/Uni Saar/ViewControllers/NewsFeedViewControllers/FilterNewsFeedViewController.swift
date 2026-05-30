//
//  FilterNewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Combine

protocol FilterNewsFeedViewDelegate: AnyObject {
    func didSelectFilterAll()
    func didSelectCustomFiltering(newsCatgroies: [Int])
}

class FilterNewsFeedViewController: UIViewController {
    @IBOutlet weak var filterTableView: UITableView! {
        didSet {
            let refreshControl = filterTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
            filterTableView.refreshControl = refreshControl
        }
    }
    lazy var filterNewsViewModel: FilterNewsViewModel = FilterNewsViewModel()
    weak var delegate: FilterNewsFeedViewDelegate?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        filterNewsViewModel.loadGetFilterList()
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

    func bindViewModel() {
        filterNewsViewModel.$didUpdatefilterList
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.relaodTableView()
            }
            .store(in: &cancellables)

        filterNewsViewModel.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.presentSingleButtonDialog(alert: alert)
            }
            .store(in: &cancellables)

        filterNewsViewModel.$showLoadingIndicator
            .dropFirst()
            .sink { [weak self] visible in
                guard let self else { return }
                visible ? filterTableView.showingLoadingView() : filterTableView.hideLoadingView()
            }
            .store(in: &cancellables)
    }

    func relaodTableView() {
        filterTableView.reloadData()
    }

    @objc private func refershLoad() {
        filterNewsViewModel.isFilterdCacheUpdated = false
        filterNewsViewModel.loadGetFilterList()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        dismissView()
        let custumFiltitedCategories = filterNewsViewModel.fetchedResultsController.fetchedObjects?.compactMap { $0 }.filter { !$0.isSelected }
        if let custumFiltitedCategories = custumFiltitedCategories {
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
        return filterNewsViewModel.fetchedResultsController.fetchedObjects?.count ?? 0
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

extension FilterNewsFeedViewController: SingleButtonDialogPresenter { }

// MARK: - NewsFilterViewCellDelegate
extension FilterNewsFeedViewController: NewsFilterViewCellDelegate {
    func didSwitchOnFilter(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = true
            }
        }
    }

    func didSwitchOffFilter(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = false
            }
        }
    }
}
