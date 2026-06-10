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
            guard let dayMenu = dayMenuViewModel else { return }
            var dayPart = AttributedString(dayMenu.dayName + " ")
            dayPart.uiKit.font = AppStyle.title1Font
            var datePart = AttributedString(dayMenu.dateValue)
            datePart.uiKit.font = AppStyle.calloutFont
            dayLabel.setAttributedText(dayPart + datePart)
        }
    }

    static var nib: UINib {
        UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        String(describing: self)
    }
}
