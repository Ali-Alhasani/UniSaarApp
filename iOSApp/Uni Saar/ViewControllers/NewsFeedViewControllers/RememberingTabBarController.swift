//
//  RememberingTabBarController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
class RememberingTabBarController: UITabBarController, UITabBarControllerDelegate {
    let lastOpenTabScreen = "selectedTabIndex"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        // Load the last selected tab if the key exists in the UserDefaults
        if UserDefaults.standard.object(forKey: self.lastOpenTabScreen) != nil {
            self.selectedIndex = UserDefaults.standard.integer(forKey: self.lastOpenTabScreen)
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Save the selected index to the UserDefaults
        UserDefaults.standard.set(self.selectedIndex, forKey: self.lastOpenTabScreen)
        UserDefaults.standard.synchronize()
    }
}
