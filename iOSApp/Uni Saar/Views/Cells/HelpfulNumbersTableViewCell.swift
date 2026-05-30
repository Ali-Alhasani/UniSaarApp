//
//  HelpfulNumbersTableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

class HelpfulNumbersTableViewCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    var viewModel: HelpfulNumbersCellViewModel? {
        didSet {
            textView.text = viewModel?.fortmatedText
        }
    }
}
