//
//  NVActivityIndicator.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 9/28/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import NVActivityIndicatorView


extension UIViewController: NVActivityIndicatorViewable {
    func showLoadingActivity(message: String? = "") {
        DispatchQueue.main.async {
            self.startAnimating(CGSize(width: 50, height: 50), message: message, type: .ballClipRotateMultiple,
                           fadeInAnimation: nil)
        }
    }

    func hideLoadingActivity() {
        stopAnimating()
    }
}
