//
//  NewsSplitViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/23/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit
// add customization to spilt view for iPad's and mac's and remove the default behavior for iPhone's
class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = .allVisible
        self.maximumPrimaryColumnWidth = UIScreen.main.bounds.width/2
        //self.minimumPrimaryColumnWidth = UIScreen.main.bounds.width/UIScreen.main.bounds.width - 2
        self.preferredPrimaryColumnWidthFraction = 0.35
        self.delegate = self
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior for iPhone's
        if UIDevice.current.userInterfaceIdiom == .phone {
            return true
        }
        return false
    }
}
