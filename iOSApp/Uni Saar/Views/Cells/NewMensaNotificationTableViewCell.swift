//
//  MensaNotificationTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 9/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class NewMensaNotificationTableViewCell: UITableViewCell {
    //@IBOutlet weak var notificationTimeLabel: UILabel!

    @IBOutlet weak var timePicker: UIDatePicker!
    var userSelectedTime: Date?
    weak var delegate: NotificationTimeDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

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
        print(sender.date)
        delegate?.tmpSelectedTime(time: sender.date)
    }
}
