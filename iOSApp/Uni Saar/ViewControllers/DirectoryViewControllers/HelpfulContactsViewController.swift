//
//  HelpfulContactsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 7/2/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class HelpfulContactsViewController: UIViewController {
    @IBOutlet var directoryTableView: UITableView! {
        didSet {
            let refreshControl = directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(refershLoad), for: .valueChanged)
            directoryTableView.refreshControl = refreshControl
        }
    }

    lazy var directoryViewModel: DirectoryViewModel = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        refershLoad()
    }

    private func setupViewModel() {
        directoryViewModel.onAlert = { [weak self] alert in self?.presentSingleButtonDialog(alert: alert) }
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if directoryViewModel.showLoadingIndicator { directoryTableView.showingLoadingView() } else { directoryTableView.hideLoadingView() }
        directoryTableView.reloadData()
    }

    func setupTableView() {
        directoryTableView.register(StaffSearchResultTableViewCell.nib, forCellReuseIdentifier: StaffSearchResultTableViewCell.identifier)
        directoryTableView.register(HelpfulNumbersTableViewCell.nib, forCellReuseIdentifier: HelpfulNumbersTableViewCell.identifier)
        directoryTableView.delegate = self
        directoryTableView.dataSource = self
        directoryTableView.layoutTableView(withOutSeparator: false)
    }

    @objc private func refershLoad() {
        Task { [weak self] in await self?.directoryViewModel.loadGetHelpHelpfulNumbers() }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension HelpfulContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        directoryViewModel.helpfulNumbersCells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        getHelpfulNumbersCell(indexPath: indexPath)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        String(localized: "HelpfulNumbers")
    }
}

extension HelpfulContactsViewController: SingleButtonDialogPresenter {}
