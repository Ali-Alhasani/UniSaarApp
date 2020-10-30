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
    @IBOutlet weak var helpfulContactsView: UIView!
    @IBOutlet weak var outerView: UIView!
    // MARK: - Instance Properties
    lazy var directoryViewModel: DirectoryViewModel = DirectoryViewModel()
    let searchController = UISearchController(searchResultsController: nil)
    private var keyboardNotification: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupTableView()
        bindViewModel()
        refershLoad()
        observeKeyboardEvents()
        // Do any additional setup after loading the view.
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
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
        helpfulContactsView.setAsCircle(cornerRadius: 8)
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
            self.directoryTableView.isHidden = false
            self.outerView.isHidden = true
            return directoryViewModel.searchResutlsCells.value.count
        }
        return 1

    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
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
        self.outerView.isHidden = true
        if let searchText = searchBar.text, searchText.count >= 3 {
            directoryViewModel.loadGetSearchResults(searchQuery: searchText)
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            self.directoryTableView.isHidden = true
            self.outerView.isHidden = false
            self.directoryTableView.reloadData()
        }
    }
}

extension DirectoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let searchText = searchBar.text, searchText.count >= 3 {
            self.load(searchText: searchText)
        }
    }
}

// load more news if the user reach the bottom of the screen
extension DirectoryViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        // the distance from bottom
        if maximumOffset - currentOffset <= 25.0 {
            if let searchText = self.searchController.searchBar.text, searchText.count >= 3 {
                self.load(isFirstTime: false, searchText: searchText)
            }
        }
    }
}
extension DirectoryViewController: SingleButtonDialogPresenter { }
extension DirectoryViewController {
    private func observeKeyboardEvents() {
        keyboardNotification = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let keyboardHeight = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            print("Keyboard height in KeyboardWillShow method: \(keyboardHeight.height)")
            self?.directoryTableView.contentInset.bottom = keyboardHeight.height
            self?.directoryTableView.verticalScrollIndicatorInsets.bottom = keyboardHeight.height
            }

        keyboardNotification = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self]  _ in
             self?.directoryTableView.verticalScrollIndicatorInsets.bottom = 0
             self?.directoryTableView.contentInset.bottom = 0
         }
    }
}
