//
//  MensaLocationSectionTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import AlamofireImage

class MensaDateHeaderSectionTableViewCell: UITableViewHeaderFooterView, UIGestureRecognizerDelegate {
    @IBOutlet weak var dayLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    var dayMenuViewModel: MensaDayMenuViewModel? {
        didSet {
            DispatchQueue.main.async {
                self.dayLabel.attributedText = self.dayMenuViewModel?.dateText
            }
        }
    }
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
}
