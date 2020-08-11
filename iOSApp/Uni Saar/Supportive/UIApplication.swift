//
//  UIApplication.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 8/1/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {

    class func topViewController(_ viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }

        return viewController
    }
}
