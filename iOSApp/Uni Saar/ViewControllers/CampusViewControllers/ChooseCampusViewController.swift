//
//  ChooseCampusViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
protocol ChooseCampusDelegate: class {
    func didChangeLocationFilter(selectedCampus: Campus, regionNeedUpdate: Bool)
}
class ChooseCampusViewController: UIViewController {
    @IBOutlet weak var filterTableView: UITableView!
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
        if selctedLocation != AppSessionManager.shared.selectedCampus {
            AppSessionManager.shared.selectedCampus = selctedLocation
            self.delegate?.didChangeLocationFilter(selectedCampus: selctedLocation, regionNeedUpdate: true)
        }
        dismissView()
    }

    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChooseCampusViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = Campus.saarbruken.title
            if selctedLocation == .saarbruken {
                cell.isSelected = true
                cell.accessoryType = .checkmark
            }
        case 1:
            cell.textLabel?.text = Campus.homburg.title
            if selctedLocation == .homburg {
                cell.isSelected = true
                cell.accessoryType = .checkmark
            }
        default:
            break
        }

        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("ChooseCampus", comment: "")
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
            self.filterTableView.reloadData()
        }
    }
}
