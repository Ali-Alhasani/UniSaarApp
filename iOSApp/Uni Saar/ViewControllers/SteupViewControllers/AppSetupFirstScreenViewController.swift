//
//  AppSetupFirstScreenViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class AppSetupFirstScreenViewController: UIViewController {

    @IBOutlet weak var saarbrukenButton: ButtonWithCheckedImageText!
    @IBOutlet weak var homburgButton: ButtonWithCheckedImageText!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        // Do any additional setup after loading the view.
        cacheCampusCoorFile()
    }
    func setUpLayout() {
        //Saarbrucken campus is always the default
        saarbrukenButton.tintColor = .white
        homburgButton.tintColor = .clear
        nextButton.setAsCircle(cornerRadius: 4)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        homburgButton.titleLabel?.textColor = UIColor.labelCustomColor
        homburgButton.backgroundColor = UIColor.secondaryFillColor
    }
    @IBAction func saarbrukenAction(_ sender: Any) {
        changeCampus(selectedCampus: Campus.saarbruken)
    }

    @IBAction func homburgAction(_ sender: UIButton) {
        changeCampus(selectedCampus: Campus.homburg)
    }
    func changeCampus(selectedCampus: Campus) {
        if AppSessionManager.shared.selectedCampus == selectedCampus {
            return
        }
        if selectedCampus == .homburg {
            homburgButton.tintColor =  .white
            saarbrukenButton.titleLabel?.textColor = UIColor.labelCustomColor
            homburgButton.backgroundColor = UIColor(named: "uniColorTint")
            saarbrukenButton.backgroundColor = UIColor.secondaryFillColor
            homburgButton.titleLabel?.textColor = UIColor.lightLabelCustomColor
            saarbrukenButton.tintColor = .clear

        } else {
            homburgButton.tintColor = .clear
            homburgButton.titleLabel?.textColor = UIColor.labelCustomColor
            homburgButton.backgroundColor = UIColor.secondaryFillColor
            saarbrukenButton.backgroundColor = UIColor(named: "uniColorTint")
            saarbrukenButton.tintColor =  .white
        }
        AppSessionManager.shared.selectedCampus = selectedCampus

    }
    @IBAction func nextButtonAction(_ sender: Any) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            if success {
                print("All set!")
                self.navigateToMainHomeScreen()
            } else {
                self.navigateToMainHomeScreen()
            }
        }
    }
    func navigateToMainHomeScreen() {
        DispatchQueue.main.async {
            MediatorDelegate.navigateToMainHomeScreen(window: self.view.window)
            self.nextSessionWelcomeScreen()
        }
    }
    func nextSessionWelcomeScreen() {
        AppSessionManager.shared.dismissWelcomeScreen = true
        AppSessionManager.saveWelcomeScreenStatus()
    }

    func cacheCampusCoorFile() {
        DispatchQueue.global(qos: .utility).async {
            Data.copyFileFromBundleToDocumentsFolder(sourceFile: "Campus_Map_Coord.json")

        }
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
