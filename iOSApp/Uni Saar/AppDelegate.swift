//
//  AppDelegate.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 13.0, *) {
            setupNavigationBarColor()
        } else {
            // Fallback on earlier versions
            window?.tintColor  = AppStyle.appGlobalTintColor
            setupNavigationBarColor2()
            // do iOS 12 specific window setup
            MediatorDelegate.configureRootViewController(window: window)
        }
        return true
    }
    @available(iOS 13.0, *)
    func setupNavigationBarColor() {
        let coloredAppearance = UINavigationBarAppearance()
        //coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = AppStyle.appNavgationMainColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().tintColor = AppStyle.backNavgationTintColor
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = AppStyle.appGlobalTintColor

    }

    func setupNavigationBarColor2() {
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = AppStyle.appNavgationMainColor
        navigationBarAppearace.tintColor = AppStyle.backNavgationTintColor
        navigationBarAppearace.isTranslucent = false
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = AppStyle.appGlobalTintColor

    }
    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        //         CoreDataStack.sharedInstance.saveContext()
        //         AppSessionManager.saveMensafiltersStatus()
    }
    // Fallback on earlier versions
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        CoreDataStack.sharedInstance.saveContext()
        AppSessionManager.saveMensafiltersStatus()
        AppSessionManager.saveNewsfiltersStatus()
        AppSessionManager.saveMoreLinksStatus()
        AppSessionManager.saveHelpfulNumberStatus()
    }
}
