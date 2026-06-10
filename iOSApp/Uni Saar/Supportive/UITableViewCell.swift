//
//  UITableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

/// commonly used TableViewCell configuration functions in the app
extension UITableViewCell {
    static var nib: UINib {
        UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        String(describing: self)
    }

    func setupEmptyCell(message: String) -> UITableViewCell {
        isUserInteractionEnabled = false
        var content = defaultContentConfiguration()
        content.text = message
        content.textProperties.numberOfLines = 0
        contentConfiguration = content
        return self
    }
}

extension UICollectionViewCell {
    static var nib: UINib {
        UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        String(describing: self)
    }
}
