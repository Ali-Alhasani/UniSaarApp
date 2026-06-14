//
//  ChooseCampusViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
protocol ChooseCampusDelegate: AnyObject {
    func didChangeLocationFilter(selectedCampus: Campus, regionNeedUpdate: Bool)
}

@MainActor
class ChooseCampusViewController: UIViewController {
    @IBOutlet var filterTableView: UITableView!
    var selctedLocation = AppSessionManager.shared.selectedCampus
    weak var delegate: ChooseCampusDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        // Do any additional setup after loading the view.
    }

    func setupTableView() {
        filterTableView.register(FilterUISwitchTableViewCell.nib, forCellReuseIdentifier: FilterUISwitchTableViewCell.identifier)
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.layoutTableView()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        actionAfterSelection()
    }

    func actionAfterSelection() {
        if selctedLocation != AppSessionManager.shared.selectedCampus {
            AppSessionManager.shared.selectedCampus = selctedLocation
            delegate?.didChangeLocationFilter(selectedCampus: selctedLocation, regionNeedUpdate: true)
        }
        dismissView()
    }

    func dismissView() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ChooseCampusViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let campus: Campus = indexPath.row == 0 ? .saarbruken : .homburg
        var content = cell.defaultContentConfiguration()
        content.text = campus.title
        cell.contentConfiguration = content
        if selctedLocation == campus {
            cell.accessoryType = .checkmark
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        String(localized: "ChooseCampus")
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            if indexPath.row == 0 {
                selctedLocation = Campus.saarbruken
            } else {
                selctedLocation = Campus.homburg
            }
            filterTableView.reloadData()
            actionAfterSelection()
        }
    }
}
