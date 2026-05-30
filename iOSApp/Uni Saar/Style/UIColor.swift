//
//  UIColor.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
public extension UIColor {
    class var uniMainColorDrak: UIColor {
        return UIColor(named: "uniColor") ?? appSystemBackgroundColor
    }
    class var uniMainColorLight: UIColor {
        return UIColor(named: "uniColorLight") ?? appSystemBackgroundColor
    }
    class var uniHeadlineColor: UIColor {
        return UIColor(named: "uniHeadlineColor") ?? appSystemLabelColor
    }
    class var uniTintColor: UIColor {
        return UIColor(named: "uniColorTint") ?? appSystemBackgroundColor
    }
    class var backNavgationTintColor: UIColor {
        return UIColor(named: "barColorTint") ?? appSystemBackgroundColor
    }
    class var appSystemBackgroundColor: UIColor {
        return UIColor.systemBackground
    }
    class var appSystemLabelColor: UIColor {
        return UIColor.label
    }
    class var flatGray: UIColor {
        return UIColor.systemGroupedBackground
    }
    class var secondaryFillColor: UIColor {
        return UIColor.secondarySystemFill
    }
    class var flatDarkGray: UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? systemGray4 : systemGray3
        }
    }
    class var labelCustomColor: UIColor {
        return UIColor.label
    }
    class var lightLabelCustomColor: UIColor {
        return UIColor.lightText
    }
}
