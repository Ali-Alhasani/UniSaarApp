//
//  MensaDateHeaderSectionTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MensaDateHeaderSectionTableViewCell: UITableViewHeaderFooterView, UIGestureRecognizerDelegate {
    @IBOutlet var dayLabel: UILabel!
    var dayMenuViewModel: MensaDayMenuViewModel? {
        didSet {
            dayLabel.attributedText = dayMenuViewModel?.dateText
        }
    }

    static var nib: UINib {
        UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        String(describing: self)
    }
}
