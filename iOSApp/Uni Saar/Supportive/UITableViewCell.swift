//
//  UITableViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
//commonly used TableViewCell configuration functions in the app
extension UITableViewCell {
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
   // return default cell with message
    func setupEmptyCell(message: String) -> UITableViewCell {
        self.isUserInteractionEnabled = false
        self.textLabel?.numberOfLines = 0
        self.textLabel?.text = message
        return self
    }
}

extension UICollectionViewCell {
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
}
