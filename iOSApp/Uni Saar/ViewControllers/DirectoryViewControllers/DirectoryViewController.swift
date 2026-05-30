//
//  DirectoryViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Combine

class DirectoryViewController: UIViewController {
    @IBOutlet weak var directoryTableView: UITableView! {
        didSet {
            let refreshControl = directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
            directoryTableView.refreshControl = refreshControl
        }
    }
    @IBOutlet weak var helpfulContactsView: UIView!
    @IBOutlet weak var outerView: UIView!
    lazy var directoryViewModel: DirectoryViewModel = DirectoryViewModel()
    let searchController = UISearchController(searchResultsController: nil)
    private var keyboardShowObserver: NSObjectProtocol?
    private var keyboardHideObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupTableView()
        bindViewModel()
        observeKeyboardEvents()
        refershLoad()
    }

    deinit {
        keyboardShowObserver.map { NotificationCenter.default.removeObserver($0) }
        keyboardHideObserver.map { NotificationCenter.default.removeObserver($0) }
    }

    func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("StaffSearch", comment: "")
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

    func bindViewModel() {
        directoryViewModel.$searchResutlsCells
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.directoryTableView.reloadData()
            }
            .store(in: &cancellables)

        directoryViewModel.$helpfulNumbersCells
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.directoryTableView.reloadData()
            }
            .store(in: &cancellables)

        directoryViewModel.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.presentSingleButtonDialog(alert: alert)
            }
            .store(in: &cancellables)

        directoryViewModel.$showLoadingIndicator
            .dropFirst()
            .sink { [weak self] visible in
                guard let self else { return }
                visible ? directoryTableView.showingLoadingView() : directoryTableView.hideLoadingView()
            }
            .store(in: &cancellables)
    }

    @objc private func refershLoad() {
        directoryViewModel.loadGetHelpHelpfulNumbers()
    }

    @objc func load(isFirstTime: Bool = true, searchText: String) {
        directoryViewModel.loadGetSearchResults(isFirstTime, searchQuery: searchText)
    }

    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    var isSearching: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!isSearchBarEmpty || searchBarScopeIsFiltering)
    }

    internal struct SegueIdentifiers {
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
    }
    func getHelpfulNumbersCell(indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch directoryViewModel.helpfulNumbersCells[safe: indexPath.row] {
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
        switch directoryViewModel.searchResutlsCells[safe: indexPath.row] {
        case .normal(let viewModel):
            performSegue(withIdentifier: SegueIdentifiers.toStaffDetails, sender: viewModel.staffId)
        case .empty, .error, .none:
            break
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isSearching { return NSLocalizedString("HelpfulNumbers", comment: "") }
        return ""
    }
}

extension DirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        outerView.isHidden = true
        if let searchText = searchController.searchBar.text, searchText.count >= 3 {
            directoryViewModel.loadGetSearchResults(searchQuery: searchText)
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

extension DirectoryViewController: SingleButtonDialogPresenter { }

extension DirectoryViewController {
    private func observeKeyboardEvents() {
        keyboardShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let keyboardHeight = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.directoryTableView.contentInset.bottom = keyboardHeight.height
            self?.directoryTableView.verticalScrollIndicatorInsets.bottom = keyboardHeight.height
        }
        keyboardHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.directoryTableView.verticalScrollIndicatorInsets.bottom = 0
            self?.directoryTableView.contentInset.bottom = 0
        }
    }
}
