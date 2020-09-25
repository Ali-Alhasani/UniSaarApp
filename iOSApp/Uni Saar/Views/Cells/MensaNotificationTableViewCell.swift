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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let timeSting = dateFormatter.string(from: selectedTime)
            notificationTimeLabel.text = NSLocalizedString("dailyTime", comment: "") + timeSting
        } else {
            notificationTimeLabel.text = NSLocalizedString("dailyTime", comment: "") + "11:15 AM"
        }
    }
}
