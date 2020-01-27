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
        if #available(iOS 13.0, *) {
            return UIColor.systemBackground
        } else {
            // Fallback on earlier versions
            return UIColor.white
        }
    }
    class var appSystemLabelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            // Fallback on earlier versions
            return UIColor.black
        }
    }
    class var flatGray: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemGroupedBackground
        } else {
            // Fallback on earlier versions
            return UIColor(red: 239, green: 242, blue: 247, alpha: 100)
        }
    }
    class var secondaryFillColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondarySystemFill
        } else {
            return UIColor.lightGray
        }
    }
    class var flatDarkGray: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor {(traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return  systemGray4
                } else {
                    return systemGray3
                }
            }
        } else {
            // Fallback on earlier versions
            return .lightGray
        }
    }
    class var labelCustomColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return .black
        }
    }
    class var lightLabelCustomColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.lightText
        } else {
            return .white
        }
    }
}
