//
//  SetupPrivacyViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
// this class is not used!
class SetupPrivacyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    // for remembering in next opening time to not open setup screen again
    func nextSessionWelcomeScreen() {
        AppSessionManager.shared.dismissWelcomeScreen = true
        AppSessionManager.saveWelcomeScreenStatus()
    }

    @IBAction func acceptDataAction(_ sender: Any) {
        AppSessionManager.shared.isEventEnabled = true
        nextScreen()
    }
    @IBAction func refuseShareDataAction(_ sender: Any) {
        AppSessionManager.shared.isEventEnabled = false
        nextScreen()
    }
    func nextScreen() {
        MediatorDelegate.navigateToMainHomeScreen(window: self.view.window)
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
