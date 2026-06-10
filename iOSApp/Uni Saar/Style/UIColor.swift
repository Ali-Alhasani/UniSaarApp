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
        UIColor(named: "uniColor") ?? appSystemBackgroundColor
    }

    class var uniMainColorLight: UIColor {
        UIColor(named: "uniColorLight") ?? appSystemBackgroundColor
    }

    class var uniHeadlineColor: UIColor {
        UIColor(named: "uniHeadlineColor") ?? appSystemLabelColor
    }

    class var uniTintColor: UIColor {
        UIColor(named: "uniColorTint") ?? appSystemBackgroundColor
    }

    class var backNavgationTintColor: UIColor {
        UIColor(named: "barColorTint") ?? appSystemBackgroundColor
    }

    class var appSystemBackgroundColor: UIColor {
        UIColor.systemBackground
    }

    class var appSystemLabelColor: UIColor {
        UIColor.label
    }

    class var flatGray: UIColor {
        UIColor.systemGroupedBackground
    }

    class var secondaryFillColor: UIColor {
        UIColor.secondarySystemFill
    }

    class var flatDarkGray: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? systemGray4 : systemGray3
        }
    }

    class var labelCustomColor: UIColor {
        UIColor.label
    }

    class var lightLabelCustomColor: UIColor {
        UIColor.lightText
    }
}
