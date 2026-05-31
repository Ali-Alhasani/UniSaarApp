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
    @IBOutlet weak var directoryTableView: UITableView! {
        didSet {
            let refreshControl = directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
            directoryTableView.refreshControl = refreshControl
        }
    }
    lazy var directoryViewModel: DirectoryViewModel = DirectoryViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        refershLoad()
    }

    override func updateProperties() {
        super.updateProperties()
        updateUI()
    }

    private func updateUI() {
        directoryViewModel.showLoadingIndicator ? directoryTableView.showingLoadingView() : directoryTableView.hideLoadingView()
        if let alert = directoryViewModel.currentAlert {
            Task { @MainActor [weak self] in
                guard let self else { return }
                directoryViewModel.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }
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
        return directoryViewModel.helpfulNumbersCells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getHelpfulNumbersCell(indexPath: indexPath)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("HelpfulNumbers", comment: "")
    }
}

extension HelpfulContactsViewController: SingleButtonDialogPresenter { }
