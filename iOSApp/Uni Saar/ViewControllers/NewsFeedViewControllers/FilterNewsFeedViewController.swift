//
//  FilterNewsFeedViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
protocol FilterNewsFeedViewDelegate: class {
    func didSelectFilterAll()
    func didSelectCustomFiltering(newsCatgroies: [Int])
}
class FilterNewsFeedViewController: UIViewController {
    @IBOutlet weak var filterTableView: UITableView! {
        didSet {
            DispatchQueue.main.async {
                let refreshControl = self.filterTableView.setUpRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
                self.filterTableView.refreshControl = refreshControl
            }
        }
    }
    // MARK: - Instance Properties
    lazy var filterNewsViewModel: FilterNewsViewModel = FilterNewsViewModel()
    weak var delegate: FilterNewsFeedViewDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        self.view.backgroundColor = UIColor.flatGray
    }
    func bindViewModel() {
        filterNewsViewModel.didUpdatefilterList.bind { [weak self] _ in
            if let `self` = self {
                self.relaodTableView()
            }
        }
        filterNewsViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        filterNewsViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.filterTableView.showingLoadingView() : self.filterTableView.hideLoadingView()
            }
        }
    }

    func relaodTableView() {
        self.filterTableView.reloadData()
    }
    @objc private func refershLoad() {
        // refresh the Categories list from the server
        filterNewsViewModel.isFilterdCacheUpdated = false
        filterNewsViewModel.loadGetFilterList()
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func doneButtonAction(_ sender: Any) {
        dismissView()
        //get the index of the filtered Catgroies
        let custumFiltitedCategories = filterNewsViewModel.fetchedResultsController.fetchedObjects?.compactMap {$0}.filter { !$0.isSelected }
        if let custumFiltitedCategories = custumFiltitedCategories {
            let filtitedCategoriesId = custumFiltitedCategories.compactMap {Int($0.categoryID)}
            self.delegate?.didSelectCustomFiltering(newsCatgroies: filtitedCategoriesId)
        }
    }

    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension FilterNewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return filterNewsViewModel.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as?  FilterUISwitchTableViewCell
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
            //update the cached news filter value
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = true
            }
        }
    }

    func didSwitchOffFilter(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            // update the cached news filter value
            let categoryEntry = filterNewsViewModel.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
            if let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: categoryEntry.objectID) as? NewsCategoriesCache {
                childEntry.isSelected = false
            }
        }
    }
}
