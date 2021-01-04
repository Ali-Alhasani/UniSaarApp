//
//  UIViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

protocol SingleButtonDialogPresenter {
    func presentSingleButtonDialog(alert: SingleButtonAlert)
}

extension SingleButtonDialogPresenter where Self: UIViewController {
    func presentSingleButtonDialog(alert: SingleButtonAlert) {
        let alertController = UIAlertController(title: alert.title,
                                                message: alert.message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: alert.action.buttonTitle,
                                                style: .default,
                                                handler: { _ in alert.action.handler?() }))
        if let tryAgainHandler = alert.action.tryAgainHandler {
            alertController.addAction(UIAlertAction(title: alert.action.tryAgainButtonTitle,
                                                    style: .default,
                                                    handler: { _ in tryAgainHandler() }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
}
