//
//  AppStyle.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
public struct AppStyle {
    static let appGlobalTintColor = UIColor.uniTintColor
    static let appNavgationMainColor = UIColor.uniMainColorLight
    static let tableViewBackgroundColor = UIColor.flatGray
    static let shadowColor = UIColor.flatDarkGray
    static let backNavgationTintColor = UIColor.backNavgationTintColor
    //tries to map mensa color code into iOS system color to have a consistent color for both light and dark mode, any change in the server color will applied directly in the app
    static func mensaCounterColor(_ serverColor: MensaColorModel) -> UIColor {
        if #available(iOS 13.0, *) {
            switch (serverColor.red, serverColor.green, serverColor.blue) {
            case (217, 38, 26):
                return .systemRed
            case (21, 135, 207):
                return .systemBlue
            case (245, 204, 43):
                return .systemYellow
            case (16, 107, 10):
                return .systemGreen
            case (135, 10, 194):
                return .systemPurple
            default:
                return UIColor(red: CGFloat(serverColor.red/256), green: CGFloat(serverColor.green/256), blue: CGFloat(serverColor.blue/256), alpha: 100)
            }
        } else {
            return UIColor(red: CGFloat(serverColor.red/256), green: CGFloat(serverColor.green/256), blue: CGFloat(serverColor.blue/256), alpha: 100)
        }
    }
    static let title1Font = UIFont.preferredFont(forTextStyle: .title1)
    static let calloutFont = UIFont.preferredFont(forTextStyle: .callout)
    static let bodyFont = UIFont.preferredFont(forTextStyle: .body)
    static let largeTitleAttributes: [NSAttributedString.Key: Any] = [.font: title1Font]
    static let calloutAttributes: [NSAttributedString.Key: Any] = [.font: calloutFont]
    static let redAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemRed]
    static let regularAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.labelCustomColor]
    static let square = "◼︎ "
    static let newLineSquare = "\n◼︎ "
    static let BULLET = "\n\t• "
    static let newLineTabFLAG = "\n\t⚠︎ "
    static let newLineFLAG  = "\n⚠︎ "
    static let triangle = "⚠︎ "
    static let warningTriangle = "⚠️ "
    static let newLine = "\n"
}
