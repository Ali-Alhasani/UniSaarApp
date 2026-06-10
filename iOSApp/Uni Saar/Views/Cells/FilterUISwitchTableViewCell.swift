//
//  FilterUISwitchTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
protocol FilterCellDelegate: AnyObject {
    func didSwitchOnFilter(indexPath: IndexPath?)
    func didSwitchOffFilter(indexPath: IndexPath?)
}

protocol NewsFilterViewCellDelegate: FilterCellDelegate {}
protocol MensaFilterCellDelegate: FilterCellDelegate {}
class FilterUISwitchTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueSwitch: UISwitch!
    var isAlCategories: Bool = false
    weak var delegate: NewsFilterViewCellDelegate?
    weak var mensaDelegate: MensaFilterCellDelegate?
    var indexPath: IndexPath?
    var cellTitle: String? {
        didSet {
            titleLabel.text = cellTitle
        }
    }

    var switchValue: Bool? {
        didSet {
            valueSwitch.isOn = switchValue ?? false
        }
    }

    @IBAction func filterSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            delegate?.didSwitchOnFilter(indexPath: indexPath)
            mensaDelegate?.didSwitchOnFilter(indexPath: indexPath)
        } else {
            delegate?.didSwitchOffFilter(indexPath: indexPath)
            mensaDelegate?.didSwitchOffFilter(indexPath: indexPath)
        }
    }
}
