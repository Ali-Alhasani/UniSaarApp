//
//  FilterUISwitchTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/12/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
protocol FilterCellDelegate: class {
    func didSwitchOnFilter(indexPath: Int?)
    func didSwitchOffFilter(indexPath: Int?)
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
    var indexPath: Int?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
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
