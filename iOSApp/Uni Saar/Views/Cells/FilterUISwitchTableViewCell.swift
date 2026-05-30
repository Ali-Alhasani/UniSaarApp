//
//  FilterUISwitchTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
protocol FilterCellDelegate: AnyObject {
    func didSwitchOnFilter(indexPath: IndexPath?)
    func didSwitchOffFilter(indexPath: IndexPath?)
}
protocol NewsFilterViewCellDelegate: FilterCellDelegate {

}
protocol MensaFilterCellDelegate: FilterCellDelegate {

}
class FilterUISwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueSwitch: UISwitch!
    var isAlCategories: Bool = false
    weak var delegate: NewsFilterViewCellDelegate?
    weak var mensaDelegate: MensaFilterCellDelegate?
    var indexPath: IndexPath?
    var cellTitle: String? {
        didSet {
            self.titleLabel.text = cellTitle
        }
    }
    var switchValue: Bool? {
        didSet {
            self.valueSwitch.isOn = switchValue ?? false
        }
    }
    @IBAction func filterSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            self.delegate?.didSwitchOnFilter(indexPath: self.indexPath)
            self.mensaDelegate?.didSwitchOnFilter(indexPath: self.indexPath)
        } else {
            self.delegate?.didSwitchOffFilter(indexPath: self.indexPath)
            self.mensaDelegate?.didSwitchOffFilter(indexPath: self.indexPath)
        }
    }
}
