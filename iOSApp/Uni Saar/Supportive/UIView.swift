//
//  UIView.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func setAsCircle(cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }

    func setAllSideShadow(shadowColor: UIColor? = nil, shadowOpacity: Float = 0.8) { // this method adds shadow to allsides
        if traitCollection.userInterfaceStyle == .dark { return }
        layer.masksToBounds = false

        if let shadowColor {
            layer.shadowColor = shadowColor.cgColor
        } else {
            layer.shadowColor = AppStyle.shadowColor.cgColor
        }
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = .zero
        layer.shadowRadius = 4
    }
}
