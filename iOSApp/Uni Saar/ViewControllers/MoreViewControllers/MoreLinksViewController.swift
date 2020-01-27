//
//  MoreLinksViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MoreLinksViewController: UITableViewController {
    lazy var moreLinksViewModel: MoreLinksViewModel = MoreLinksViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        moreLinksViewModel.loadGetMoreLinks()
        setRefreshControl()
        // Do any additional setup after loading the view.
    }

    func bindViewModel() {
        moreLinksViewModel.linksCells.bind { [weak self] _ in
            if let `self` = self {
                self.tableView.reloadData()
            }
        }
        moreLinksViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        moreLinksViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.tableView.showingLoadingView() : self.tableView.hideLoadingView()
            }
        }
    }
    func setRefreshControl() {
        let refreshControl = self.tableView.setUpRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    @objc private func refershLoad() {
        moreLinksViewModel.loadGetMoreLinks()
    }
    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toLinkDetails = "toLinkDetails"
        static let toSettings = "toSettings"
        static let toAboutApp = "toAboutApp"
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
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
            return moreLinksViewModel.linksCells.value.count
        }
        return moreLinksViewModel.extraCells.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        if  indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "moreLinksCell")
            cell?.textLabel?.text = moreLinksViewModel.extraCells[safe: indexPath.row]
            return cell ?? defaultCell
        } else {
            switch moreLinksViewModel.linksCells.value[safe: indexPath.row] {
            case .normal(let viewModel):
                let cell = tableView.dequeueReusableCell(withIdentifier: "moreLinksCell")
                cell?.textLabel?.text = viewModel.nameText
                cell?.textLabel?.numberOfLines = 0
                return cell ?? defaultCell
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
            switch moreLinksViewModel.linksCells.value[safe: indexPath.row] {
            case .normal(let viewModel):
                self.performSegue(withIdentifier: SegueIdentifiers.toLinkDetails, sender: viewModel)
            case .empty, .error, .none:
                // nop
                break
            }
        } else {
            if moreLinksViewModel.extraCells[safe: indexPath.row] == NSLocalizedString("AppSettings", comment: "") {
                self.performSegue(withIdentifier: SegueIdentifiers.toSettings, sender: self)
            } else if moreLinksViewModel.extraCells[safe: indexPath.row] == NSLocalizedString("AboutApp", comment: "") {
                self.performSegue(withIdentifier: SegueIdentifiers.toAboutApp, sender: self)
            }
        }
    }

}
extension MoreLinksViewController: SingleButtonDialogPresenter {}
