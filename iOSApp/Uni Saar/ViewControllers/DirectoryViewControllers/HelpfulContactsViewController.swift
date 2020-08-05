//
//  HelpfulContactsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 7/2/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class HelpfulContactsViewController: UIViewController {
    @IBOutlet weak var directoryTableView: UITableView! {
        didSet {
            let refreshControl = self.directoryTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
            self.directoryTableView.refreshControl = refreshControl
        }
    }
    // MARK: - Instance Properties
    lazy var directoryViewModel: DirectoryViewModel = DirectoryViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        refershLoad()

        // Do any additional setup after loading the view.
    }
    func setupTableView() {
        directoryTableView.register(StaffSearchResultTableViewCell.nib, forCellReuseIdentifier: StaffSearchResultTableViewCell.identifier)
        directoryTableView.register(HelpfulNumbersTableViewCell.nib, forCellReuseIdentifier: HelpfulNumbersTableViewCell.identifier)
        directoryTableView.delegate = self
        directoryTableView.dataSource = self
        directoryTableView.layoutTableView(withOutSeparator: false)
    }
    func bindViewModel() {
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension HelpfulContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directoryViewModel.helpfulNumbersCells.value.count

    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getHelpfulNumbersCell(indexPath: indexPath)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("HelpfulNumbers", comment: "")
    }

}
extension HelpfulContactsViewController: SingleButtonDialogPresenter { }
