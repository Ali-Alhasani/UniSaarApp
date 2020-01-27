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
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
    }
    func setAllSideShadow(shadowColor: UIColor? = nil, shadowOpacity: Float = 0.8) { // this method adds shadow to allsides
        // no shdow in dark mode
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                return
            }
        }
        self.layer.masksToBounds = false

        if let shadowColor = shadowColor {
            self.layer.shadowColor = shadowColor.cgColor
        } else {
            self.layer.shadowColor = AppStyle.shadowColor.cgColor
        }
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 4
    }
}
