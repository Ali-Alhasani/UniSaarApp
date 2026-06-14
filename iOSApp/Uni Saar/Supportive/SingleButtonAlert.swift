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
    let buttonTitle: String = .init(localized: "AlertOkActionTitle")
    let tryAgainButtonTitle: String = .init(localized: "tryAgain")
    let tryAgainHandler: (@MainActor () -> Void)?
}

struct SingleButtonAlert {
    let title: String = .init(localized: "AlertTitle")
    let message: String?
    let action: AlertAction
}

extension UIViewController {
    func errorAlert(_ errorMessage: String) -> UIAlertController {
        let alert = UIAlertController(title: String(localized: "AlertTitle"), message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "AlertOkActionTitle"), style: .default, handler: nil))
        return alert
    }

    func succesAlertWithHandler(_ errorMessage: String, _ handler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: String(localized: "AlertTitle"), message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "AlertOkActionTitle"), style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: String(localized: "AlertCancelActionTitle"), style: .cancel, handler: nil))
        return alert
    }
}
