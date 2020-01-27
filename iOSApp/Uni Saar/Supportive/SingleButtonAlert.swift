//
//  SingleButtonAlert.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
struct AlertAction {
    let buttonTitle: String = NSLocalizedString("AlertOkActionTitle", comment: "")
    let handler: (() -> Void)?
}

struct SingleButtonAlert {
    let title: String = NSLocalizedString("AlertTitle", comment: "")
    let message: String?
    let action: AlertAction
}
extension UIAlertController {

    func errorAlert(_ errorMessage: String) -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("AlertTitle", comment: ""), message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("AlertOkActionTitle", comment: ""), style: .default, handler: nil))
        return alert
    }
    func succesAlertWithHandler(_ errorMessage: String, _ handler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("AlertTitle", comment: ""), message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("AlertOkActionTitle", comment: ""), style: .default, handler: handler))
        return alert
    }
}
