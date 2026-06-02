//
//  MensaMenuTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MensaMenuTableViewCell: UITableViewCell {
    @IBOutlet var counterNameLabel: UILabel!
    @IBOutlet var mealNameLabel: UILabel!
    @IBOutlet var componentsLabel: UILabel!
    @IBOutlet var openingHoursLabel: UILabel!
    @IBOutlet var outerView: UIView!
    @IBOutlet var colorView: UIView!
    @IBOutlet var noticesLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            setUpLayout()
        }
    }

    @MainActor func setUpLayout() {
        outerView.setAsCircle(cornerRadius: 5)
        colorView.layer.cornerRadius = 5
        colorView.backgroundColor = .systemRed
        // if the language is RTL it should be switch to [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        colorView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        outerView.setAllSideShadow()
    }
}

extension MensaMenuTableViewCell: MensaMenuViewModelView {
    var counterLabel: UILabel? {
        counterNameLabel
    }

    var mealDisplayNameLabel: UILabel? {
        mealNameLabel
    }

    var hoursLabel: UILabel? {
        openingHoursLabel
    }

    var mealsLabel: UILabel? {
        componentsLabel
    }

    var counterColorView: UIView? {
        colorView
    }

    var noticeLabel: UILabel? {
        noticesLabel
    }
}
