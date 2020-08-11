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
    @IBOutlet weak var notificationTimeLabel: UILabel!
    var selectedTime: Date? {
        didSet {
            AppSessionManager.shared.foodAlarmTime = selectedTime
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFoodAlarmStatus()

        //setTheAlertTime()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AppSessionManager.shared.selectedCampus == Campus.saarbruken {
            tableView.selectRow(at: IndexPath.init(row: 0, section: 1), animated: false, scrollPosition: .none)
            if let cell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 1)) {
                cell.accessoryType = .checkmark
            }
        } else {
            tableView.selectRow(at: IndexPath.init(row: 1, section: 1), animated: false, scrollPosition: .none)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppSessionManager.shared.isFoodAlarmEnabled = toggleSwitch?.isOn ?? false
        AppSessionManager.saveFoodAlarmStatus()
    }

    func updateView() {
        if let selectedTime = selectedTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let timeSting = dateFormatter.string(from: selectedTime)
            notificationTimeLabel.text = "the daily notification time is " + timeSting
        } else {
            notificationTimeLabel.text = "the daily notification time is " + "11:15 AM"
        }
    }

    func loadFoodAlarmStatus() {
        AppSessionManager.loadFoodAlarmTime()
        DispatchQueue.main.async {
            self.toggleSwitch.isOn = AppSessionManager.shared.isFoodAlarmEnabled
            self.updateTableView()
            if let alarmSavedTime = AppSessionManager.shared.foodAlarmTime {
                self.selectedTime = alarmSavedTime
            }
            self.updateView()
        }
    }

    func saveFoodAlarmStatus() {
        AppSessionManager.saveFoodAlarmStatus()
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if indexPath.section == 1 && indexPath.row == 0 {
                cell.accessoryType = .checkmark
                AppSessionManager.shared.selectedCampus = Campus.saarbruken
                notifyCampusView()
            } else if indexPath.section == 1 && indexPath.row == 1 {
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

    //    func setTheAlertTime() {
    //        var components = DateComponents()
    //        components.timeZone = TimeZone.current
    //        components.hour = 11
    //        components.minute = 0
    //
    //        //        let date = Date()
    //        var calendar = Calendar.current
    //        calendar.locale = Locale.current
    //        calendar.timeZone = TimeZone.current
    //        //        let monthInterval = calendar.dateInterval(of: .month, for: date)!
    //        //        calendar.dateInterval(of: .month, for: date)!
    //        //
    //        //        calendar.dateComponents([.hour],
    //        //                        from: monthInterval.start,
    //        //                        to: monthInterval.end)
    //        //        .hour // 744
    //        let dateComponents = DateComponents(calendar: calendar, timeZone: .current, hour: 11, minute: 15, second: 0)
    //        let formatedDate = calendar.date(from: dateComponents)
    //        let string = "20:32 Wed, 30 Oct 2019"
    //        let formatter4 = DateFormatter()
    //        formatter4.dateFormat = "HH:mm E, d MMM y"
    //        formatter4.timeZone = TimeZone.current
    //        formatter4.locale = Locale.current
    //        print(formatter4.date(from: string) ?? "Unknown date")
    //
    //        //        let dateString = "May 2, 2018 at 3:31 PM"
    //        //
    //        //        let dateFormatter = DateFormatter()
    //        //        dateFormatter.dateFormat = "MMM dd, yyyy 'at' hh:mm a"
    //        //        dateFormatter.timeZone = TimeZone(identifier: "UTC")
    //        //        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    //        let date = formatter4.date(from: string)
    //        if let date = date {
    //            timerPicker.date = date
    //        }
    //    }

    @IBAction func foodAlarmSwitch(_ sender: UISwitch) {
        checkNotificationStatus()
    }

    func updateTableView() {
        // to initiate smooth animation
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
            } else {
                self.updateSwitchButton(switchOn: true)
            }
        }
    }

    func updateSwitchButton(switchOn: Bool = false) {
        DispatchQueue.main.async {
            self.toggleSwitch.isOn = switchOn
            self.updateTableView()
            if switchOn {
                self.scheduleNotification()
            } else {
                self.cancelNotification()
            }
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

    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Today in Mensa"
        content.body = "A complete meal and vegetarian meal and variety of free flow meals, check now.."
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let someDateTime = formatter.date(from: "11:15")

        let date = selectedTime ?? someDateTime ?? Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour ?? 11
        dateComponents.minute = components.minute ?? 15
        dateComponents.timeZone = TimeZone.current
        dateComponents.calendar = Calendar.current
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "MensaNotifcation", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["MensaNotifcation"])
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "toNotificationTime", let destinationViewController = segue.destination as? UINavigationController,
            let topView = destinationViewController.topViewController as? NotificationTimeViewController {
            topView.delegate = self
            topView.selectedTime = selectedTime
        }
    }
}

extension SettingsViewController: NotificationTimeDelegate {
    func selectedTime(time: Date) {
        self.selectedTime = time
        updateView()
        cancelNotification()
        scheduleNotification()
    }
}
