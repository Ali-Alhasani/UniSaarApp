//
//  MoreLinksViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class MoreLinksViewController: UITableViewController {
    lazy var moreLinksViewModel: MoreLinksViewModel = MoreLinksViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setRefreshControl()
        Task { [weak self] in await self?.moreLinksViewModel.loadGetMoreLinks() }
    }

    override func updateProperties() {
        super.updateProperties()
        updateUI()
    }

    private func updateUI() {
        moreLinksViewModel.showLoadingIndicator ? tableView.showingLoadingView() : tableView.hideLoadingView()
        if let alert = moreLinksViewModel.currentAlert {
            Task { @MainActor [weak self] in
                guard let self else { return }
                moreLinksViewModel.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }
        tableView.reloadData()
        requestReview()
    }

    func setRefreshControl() {
        let refreshControl = tableView.setUpRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    @objc private func refershLoad() {
        Task { [weak self] in await self?.moreLinksViewModel.loadGetMoreLinks() }
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }

    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toLinkDetails = "toLinkDetails"
        static let toSettings = "toSettings"
        static let toAboutApp = "toAboutApp"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toLinkDetails,
           let destinationViewController = segue.destination as? MoreLinksDetailsViewController,
           let viewModel = sender as? MoreLinksCellViewModel {
            destinationViewController.linkItem = viewModel
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MoreLinksViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return moreLinksViewModel.linksCells.count
        }
        return moreLinksViewModel.extraCells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "moreLinksCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = moreLinksViewModel.extraCells[safe: indexPath.row]
            cell.contentConfiguration = content
            return cell
        } else {
            switch moreLinksViewModel.linksCells[safe: indexPath.row] {
            case .normal(let viewModel):
                let cell = tableView.dequeueReusableCell(withIdentifier: "moreLinksCell", for: indexPath)
                var content = cell.defaultContentConfiguration()
                content.text = viewModel.nameText
                content.textProperties.numberOfLines = 0
                cell.contentConfiguration = content
                return cell
            case .error(let message):
                return defaultCell.setupEmptyCell(message: message)
            case .empty:
                return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyLinks", comment: ""))
            case .none:
                return defaultCell
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch moreLinksViewModel.linksCells[safe: indexPath.row] {
            case .normal(let viewModel):
                performSegue(withIdentifier: SegueIdentifiers.toLinkDetails, sender: viewModel)
            case .empty, .error, .none:
                break
            }
        } else {
            if moreLinksViewModel.extraCells[safe: indexPath.row] == NSLocalizedString("AppSettings", comment: "") {
                performSegue(withIdentifier: SegueIdentifiers.toSettings, sender: self)
            } else if moreLinksViewModel.extraCells[safe: indexPath.row] == NSLocalizedString("AboutApp", comment: "") {
                performSegue(withIdentifier: SegueIdentifiers.toAboutApp, sender: self)
            }
        }
    }
}

extension MoreLinksViewController: SingleButtonDialogPresenter {}
