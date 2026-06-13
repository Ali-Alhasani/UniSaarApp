//
//  SetupPrivacyViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

/// this class is not used!
@MainActor
class SetupPrivacyViewController: UIViewController {
    /// for remembering in next opening time to not open setup screen again
    func nextSessionWelcomeScreen() {
        AppSessionManager.shared.dismissWelcomeScreen = true
    }

    @IBAction func acceptDataAction(_ sender: Any) {
        nextScreen()
    }

    @IBAction func refuseShareDataAction(_ sender: Any) {
        nextScreen()
    }

    func nextScreen() {
        MediatorDelegate.navigateToMainHomeScreen(window: view.window)
        nextSessionWelcomeScreen()
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}
