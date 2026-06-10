//
//  UIButton.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

class ButtonWithCheckedImageText: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        semanticContentAttribute = .forceRightToLeft
    }
}
