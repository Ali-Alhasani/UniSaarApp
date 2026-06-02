//
//  NewMensaNotificationTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 9/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class NewMensaNotificationTableViewCell: UITableViewCell {
    @IBOutlet var timePicker: UIDatePicker!
    var userSelectedTime: Date?
    weak var delegate: NotificationTimeDelegate?

    var notificationSelectedTime: Date? {
        didSet {
            updateView()
        }
    }

    func updateView() {
        if let selectedTime = notificationSelectedTime {
            timePicker.date = selectedTime
        }
    }

    @IBAction func timePickerAction(_ sender: UIDatePicker) {
        userSelectedTime = sender.date
        delegate?.tmpSelectedTime(time: sender.date)
    }
}
