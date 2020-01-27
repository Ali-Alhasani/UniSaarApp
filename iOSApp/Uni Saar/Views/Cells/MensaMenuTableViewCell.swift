//
//  MensaMenuTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MensaMenuTableViewCell: UITableViewCell {
    @IBOutlet weak var counterNameLabel: UILabel!
    @IBOutlet weak var mealNameLabel: UILabel!
    @IBOutlet weak var componentsLabel: UILabel!
    @IBOutlet weak var openingHoursLabel: UILabel!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var noticesLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setUpLayout()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    func setUpLayout() {
        outerView.setAsCircle(cornerRadius: 5)
        colorView.layer.cornerRadius = 5
        colorView.backgroundColor = .systemRed
        //if the language is RTL it should be switch to [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        colorView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        outerView.setAllSideShadow()
    }
}
extension MensaMenuTableViewCell: MensaMenuViewModelView {
    var counterLabel: UILabel? {
        return counterNameLabel
    }
    var mealDisplayNameLabel: UILabel? {
        return mealNameLabel
    }
    var hoursLabel: UILabel? {
        return openingHoursLabel
    }
    var mealsLabel: UILabel? {
        return componentsLabel
    }
    var counterColorView: UIView? {
        return colorView
    }
    var noticeLabel: UILabel? {
        return noticesLabel
    }
}
