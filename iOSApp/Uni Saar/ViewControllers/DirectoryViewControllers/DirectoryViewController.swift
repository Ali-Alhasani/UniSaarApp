//
//  DirectoryViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class DirectoryViewController: UIViewController {
    @IBOutlet weak var directoryTableView: UITableView! {
        didSet {
            let refreshControl = self.directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
            self.directoryTableView.refreshControl = refreshControl
        }
    }
    // MARK: - Instance Properties
    lazy var directoryViewModel: DirectoryViewModel = DirectoryViewModel()
    let searchController = UISearchController(searchResultsController: nil)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupTableView()
        bindViewModel()
        refershLoad()
        // Do any additional setup after loading the view.
    }

    func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("StaffSearch", comment: "")
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.backgroundColor = UIColor.appSystemBackgroundColor
        } else {
            // Fallback on earlier versions
        }
        navigationItem.searchController = searchController
        definesPresentationContext = true
        searchController.searchBar.delegate = self
    }
    func setupTableView() {
        directoryTableView.register(StaffSearchResultTableViewCell.nib, forCellReuseIdentifier: StaffSearchResultTableViewCell.identifier)
        directoryTableView.register(HelpfulNumbersTableViewCell.nib, forCellReuseIdentifier: HelpfulNumbersTableViewCell.identifier)
        directoryTableView.delegate = self
        directoryTableView.dataSource = self
        directoryTableView.layoutTableView(withOutSeparator: false)
    }
    func bindViewModel() {
        directoryViewModel.searchResutlsCells.bind { [weak self] _ in
            if let `self` = self {
                self.directoryTableView.reloadData()
            }
        }
        directoryViewModel.helpfulNumbersCells.bind { [weak self] _ in
            if let `self` = self {
                self.directoryTableView.reloadData()
            }
        }
        directoryViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        directoryViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.directoryTableView.showingLoadingView() : self.directoryTableView.hideLoadingView()
            }
        }
    }
    @objc private func refershLoad() {
        directoryViewModel.loadGetHelpHelpfulNumbers()
    }
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    var isSearching: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!isSearchBarEmpty || searchBarScopeIsFiltering)
    }
    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toStaffDetails = "toStaffDetails"
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueIdentifiers.toStaffDetails, let destination = segue.destination as? UINavigationController,
            let destinationViewController = destination.topViewController as? StaffDetailsViewController,
            let staffId = sender as? Int {
            destinationViewController.staffId = staffId
        }
    }
}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension DirectoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return directoryViewModel.searchResutlsCells.value.count
        }
        return directoryViewModel.helpfulNumbersCells.value.count

    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        if isSearching {
            switch directoryViewModel.searchResutlsCells.value[safe: indexPath.row] {
            case .normal(let viewModel):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: StaffSearchResultTableViewCell.identifier, for: indexPath) as? StaffSearchResultTableViewCell else {
                    return defaultCell
                }
                cell.viewModel = viewModel
                return cell
            case .error(let message):
                return defaultCell.setupEmptyCell(message: message)
            case .empty:
                return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyResults", comment: ""))
            case .none:
                return defaultCell
            }
        } else {
            return getHelpfulNumbersCell(indexPath: indexPath)
        }
    }
    // move helpful numbers cell out to reduce function complexity
    func getHelpfulNumbersCell(indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch directoryViewModel.helpfulNumbersCells.value[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = directoryTableView.dequeueReusableCell(withIdentifier: HelpfulNumbersTableViewCell.identifier, for: indexPath) as? HelpfulNumbersTableViewCell else {
                return defaultCell
            }
            cell.viewModel = viewModel
            cell.selectionStyle = .none
            return cell
        case .error(let message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyResults", comment: ""))
        case .none:
            return defaultCell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch directoryViewModel.searchResutlsCells.value[safe: indexPath.row] {
        case .normal(let viewModel):
            self.performSegue(withIdentifier: SegueIdentifiers.toStaffDetails, sender: viewModel.staffId)
        case .empty, .error, .none:
            // nop
            break
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isSearching {
            return NSLocalizedString("HelpfulNumbers", comment: "")
        }
        return ""
    }

}
extension DirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        if let searchText = searchBar.text, searchText.count >= 3 {
            directoryViewModel.loadGetSearchResults(searchQuery: searchText)
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            self.directoryTableView.reloadData()
        }
    }
}

extension DirectoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let searchText = searchBar.text, searchText.count >= 3 {
            directoryViewModel.loadGetSearchResults(searchQuery: searchText)
        }
    }
}

extension DirectoryViewController: SingleButtonDialogPresenter { }
