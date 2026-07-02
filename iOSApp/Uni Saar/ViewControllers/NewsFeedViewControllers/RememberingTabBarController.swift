//
//  RememberingTabBarController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/22/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class RememberingTabBarController: UITabBarController, UITabBarControllerDelegate {
    let lastOpenTabScreen = "selectedTabIndex"

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        installSwiftUINewsFeed()

        // Load the last selected tab if the key exists in the UserDefaults
        if let lastOpenTab = UserDefaults.standard.object(forKey: lastOpenTabScreen) as? Int {
            selectedIndex = lastOpenTab
        }
    }

    /// Replaces the storyboard's UIKit news tab (index 0) with the SwiftUI feed,
    /// keeping the original tab bar item. Part of the incremental SwiftUI migration.
    private func installSwiftUINewsFeed() {
        guard var controllers = viewControllers, let newsTab = controllers.first else { return }
        let host = UIHostingController(rootView: NavigationStack { NewsFeedView() })
        host.tabBarItem = newsTab.tabBarItem
        controllers[0] = host
        viewControllers = controllers
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Save the selected index to the UserDefaults
        UserDefaults.standard.set(selectedIndex, forKey: lastOpenTabScreen)
    }
}
