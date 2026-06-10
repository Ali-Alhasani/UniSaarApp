//
//  UILabel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 6/7/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

import UIKit

extension UILabel {
    /// Phase 3 bridge: remove when UIKit labels are replaced with SwiftUI Text,
    /// which accepts AttributedString natively without conversion.
    func setAttributedText(_ attributed: AttributedString) {
        attributedText = NSAttributedString(attributed)
    }
}
