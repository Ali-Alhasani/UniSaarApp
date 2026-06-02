//
//  StaffSearchResultTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class StaffSearchResultTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var fullNameLabel: UILabel!
    var viewModel: DirectorySearchResutlsCellViewModel? {
        didSet {
            titleLabel.text = viewModel?.titleText
            fullNameLabel.text = viewModel?.nameText
        }
    }
}
