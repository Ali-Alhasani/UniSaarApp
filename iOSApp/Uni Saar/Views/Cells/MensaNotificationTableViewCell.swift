//
//  MensaNotificationTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 9/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MensaNotificationTableViewCell: UITableViewCell {
    @IBOutlet weak var notificationTimeLabel: UILabel!

    var notificationSelectedTime: Date? {
        didSet {
            updateView()
        }
    }

    func updateView() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let time: Date
        if let selectedTime = notificationSelectedTime {
            time = selectedTime
        } else {
            var components = DateComponents()
            components.hour = 11
            components.minute = 15
            time = Calendar.current.date(from: components) ?? Date()
        }
        notificationTimeLabel.text = NSLocalizedString("dailyTime", comment: "") + formatter.string(from: time)
    }
}
