//
//  DirectoryViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class DirectoryViewController: UIViewController {
    @IBOutlet var directoryTableView: UITableView! {
        didSet {
            let refreshControl = directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(refershLoad), for: .valueChanged)
            directoryTableView.refreshControl = refreshControl
        }
    }

    @IBOutlet var helpfulContactsView: UIView!
    @IBOutlet var outerView: UIView!
    private var pageSize: Int {
        UIDevice.current.userInterfaceIdiom == .pad ? 16 : 10
    }

    lazy var directoryViewModel: DirectoryViewModel = .init(pageSize: pageSize)
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupTableView()
        observeKeyboardEvents()
        setupViewModel()
        refershLoad()
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if directoryViewModel.showLoadingIndicator { directoryTableView.showingLoadingView() } else { directoryTableView.hideLoadingView() }
        directoryTableView.reloadData()
    }

    private func setupViewModel() {
        directoryViewModel.onAlert = { [weak self] alert in self?.presentSingleButtonDialog(alert: alert) }
        directoryViewModel.onRetry = { [weak self] in self?.refershLoad() }
        // bindings only — load fires last in viewDidLoad
    }

    func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "StaffSearch")
        searchController.searchBar.searchTextField.backgroundColor = UIColor.appSystemBackgroundColor
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
        helpfulContactsView.setAsCircle(cornerRadius: 8)
    }

    @objc private func refershLoad() {
        Task { [weak self] in await self?.directoryViewModel.loadGetHelpHelpfulNumbers() }
    }

    @objc func load(isFirstTime: Bool = true, searchText: String) {
        Task { [weak self] in await self?.directoryViewModel.loadGetSearchResults(isFirstTime, searchQuery: searchText) }
    }

    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }

    var isSearching: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!isSearchBarEmpty || searchBarScopeIsFiltering)
    }

    enum SegueIdentifiers {
        static let toStaffDetails = "toStaffDetails"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toStaffDetails,
           let destination = segue.destination as? UINavigationController,
           let destinationViewController = destination.topViewController as? StaffDetailsViewController,
           let staffId = sender as? Int {
            destinationViewController.staffId = staffId
        }
    }
}

extension DirectoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            directoryTableView.isHidden = false
            outerView.isHidden = true
            return directoryViewModel.searchResutlsCells.count
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch directoryViewModel.searchResutlsCells[safe: indexPath.row] {
        case let .normal(viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: StaffSearchResultTableViewCell.identifier, for: indexPath) as? StaffSearchResultTableViewCell else {
                return defaultCell
            }
            cell.viewModel = viewModel
            return cell
        case let .error(message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: String(localized: "EmptyResults"))
        case .none:
            return defaultCell
        }
    }

    func getHelpfulNumbersCell(indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch directoryViewModel.helpfulNumbersCells[safe: indexPath.row] {
        case let .normal(viewModel):
            guard let cell = directoryTableView.dequeueReusableCell(withIdentifier: HelpfulNumbersTableViewCell.identifier, for: indexPath) as? HelpfulNumbersTableViewCell else {
                return defaultCell
            }
            cell.viewModel = viewModel
            cell.selectionStyle = .none
            return cell
        case let .error(message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: String(localized: "EmptyResults"))
        case .none:
            return defaultCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch directoryViewModel.searchResutlsCells[safe: indexPath.row] {
        case let .normal(viewModel):
            performSegue(withIdentifier: SegueIdentifiers.toStaffDetails, sender: viewModel.staffId)
        case .empty, .error, .none:
            break
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isSearching { return String(localized: "HelpfulNumbers") }
        return ""
    }
}

extension DirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        outerView.isHidden = true
        if let searchText = searchController.searchBar.text, searchText.count >= 3 {
            Task { [weak self] in await self?.directoryViewModel.loadGetSearchResults(searchQuery: searchText) }
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        directoryTableView.isHidden = true
        outerView.isHidden = false
        directoryTableView.reloadData()
    }
}

extension DirectoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let searchText = searchBar.text, searchText.count >= 3 {
            load(searchText: searchText)
        }
    }
}

extension DirectoryViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        if maximumOffset - currentOffset <= 25.0 {
            if let searchText = searchController.searchBar.text, searchText.count >= 3 {
                load(isFirstTime: false, searchText: searchText)
            }
        }
    }
}

extension DirectoryViewController: SingleButtonDialogPresenter {}

extension DirectoryViewController {
    private func observeKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardHeight = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        directoryTableView.contentInset.bottom = keyboardHeight.height
        directoryTableView.verticalScrollIndicatorInsets.bottom = keyboardHeight.height
    }

    @objc private func keyboardWillHide() {
        directoryTableView.verticalScrollIndicatorInsets.bottom = 0
        directoryTableView.contentInset.bottom = 0
    }
}
