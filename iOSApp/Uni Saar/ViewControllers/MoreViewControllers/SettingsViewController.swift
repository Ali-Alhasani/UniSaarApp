//
//  SettingsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //setTheAlertTime()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AppSessionManager.shared.selectedCampus == Campus.saarbruken {
            tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .none)
            if let cell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 0)) {
                cell.accessoryType = .checkmark
            }
        } else {
            tableView.selectRow(at: IndexPath.init(row: 1, section: 0), animated: false, scrollPosition: .none)
        }
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if indexPath.section == 0 && indexPath.row == 0 {
                cell.accessoryType = .checkmark
                AppSessionManager.shared.selectedCampus = Campus.saarbruken
                notifyCampusView()
            } else if indexPath.section == 0 && indexPath.row == 1 {
                cell.accessoryType = .checkmark
                AppSessionManager.shared.selectedCampus = Campus.homburg
                notifyCampusView()
            }
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    func notifyCampusView() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CampusSettingsDidUpdate"), object: nil)
    }

    func goToAppSettings() {
        DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}
