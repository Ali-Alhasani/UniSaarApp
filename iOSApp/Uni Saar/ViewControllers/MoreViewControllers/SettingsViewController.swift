//
//  SettingsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var timerPicker: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        setTheAlertTime()
        timerPicker.addTarget(self, action: #selector(handleDatePicker), for: .valueChanged)
        // Do any additional setup after loading the view.
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.section == 0 && indexPath.row == 1 && toggleSwitch.isOn == false {
            return 0.0  // collapsed
        }
        // expanded with row height of parent
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    func setTheAlertTime() {
        var components = DateComponents()
        components.timeZone = TimeZone.current
        components.hour = 11
        components.minute = 0

        //        let date = Date()
        var calendar = Calendar.current
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        //        let monthInterval = calendar.dateInterval(of: .month, for: date)!
        //        calendar.dateInterval(of: .month, for: date)!
        //
        //        calendar.dateComponents([.hour],
        //                        from: monthInterval.start,
        //                        to: monthInterval.end)
        //        .hour // 744
        let dateComponents = DateComponents(calendar: calendar, timeZone: .current, hour: 11, minute: 15, second: 0)
        let formatedDate = calendar.date(from: dateComponents)
        let string = "20:32 Wed, 30 Oct 2019"
        let formatter4 = DateFormatter()
        formatter4.dateFormat = "HH:mm E, d MMM y"
        formatter4.timeZone = TimeZone.current
        formatter4.locale = Locale.current
        print(formatter4.date(from: string) ?? "Unknown date")

        //        let dateString = "May 2, 2018 at 3:31 PM"
        //
        //        let dateFormatter = DateFormatter()
        //        dateFormatter.dateFormat = "MMM dd, yyyy 'at' hh:mm a"
        //        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        //        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter4.date(from: string)
        if let date = date {
            timerPicker.date = date
        }
    }

    @IBAction func foodAlarmSwitch(_ sender: UISwitch) {
        // to initiate smooth animation
        updateTableView()
    }

    func updateTableView() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.enableNotification()
                self.updateSwitchButton()
            } else if settings.authorizationStatus != .authorized {
                self.updateSwitchButton()
                self.notificationAlert()
            }
        }
    }

    func updateSwitchButton(switchOn: Bool = false) {
        DispatchQueue.main.async {
            self.toggleSwitch.isOn = switchOn
            self.updateTableView()
        }
    }

    func enableNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.updateSwitchButton(switchOn: true)
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    func notificationAlert() {
        DispatchQueue.main.async {
            self.showAlert(self.succesAlertWithHandler("Please enable the notification permission in the app settings", { (_) in
                self.goToAppSettings()
            }))
        }

    }

    func showAlert(_ alert: UIAlertController) {
        guard self.presentedViewController != nil else {
            self.present(alert, animated: true, completion: nil)
            return
        }
    }

    func goToAppSettings() {
        DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }

    @objc func handleDatePicker(_ datePicker: UIDatePicker) {
        print("time ", datePicker.date)
    }

    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Late wake up call"
        content.body = "The early bird catches the worm, but the second mouse gets the cheese."
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
}
