//
//  SceneDelegate.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
// this class is mediator for comman window setup between SceneDelegate and AppDelegate
class MediatorDelegate: UIResponder {
    static var window: UIWindow?
    static var sceneDelegate: SceneDelegate?
    static func configureRootViewController(window: UIWindow?, sceneDelegate: SceneDelegate? = nil) {
        AppSessionManager.loadWelcomeScreenStatus()
        MediatorDelegate.sceneDelegate = sceneDelegate
         //DispatchQueue.main.async {
             AppSessionManager.loadMensafiltersStatus()
             AppSessionManager.loadNewsfiltersStatus()
             AppSessionManager.loadMoreLinksStatus()
             AppSessionManager.loadHelpfulNumberStatus()
       // }
        if !AppSessionManager.shared.dismissWelcomeScreen, window?.rootViewController as? AppSetupFirstScreenViewController != nil {
            return
        } else {
            navigateToMainHomeScreen(window: window)
        }

    }
    static func navigateToMainHomeScreen(window: UIWindow?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "mainTabBar") as? UITabBarController
        // custom customization for macOs by replacing the bottom tab bar with top toolbar
        #if targetEnvironment(macCatalyst)
        if let windowScene =  window?.windowScene {
            MediatorDelegate.window = window
            if let titlebar = windowScene.titlebar {
                let toolbar = NSToolbar(identifier: "testToolbar")
                //hide tab bar in macOs app
                mainTabBarController?.tabBar.isHidden = true
                toolbar.delegate = MediatorDelegate.sceneDelegate
                toolbar.allowsUserCustomization = true
                toolbar.centeredItemIdentifier = NSToolbarItem.Identifier(rawValue: "tabBarReplacement")
                titlebar.titleVisibility = .hidden

                titlebar.toolbar = toolbar
            }
        }
        #endif
        window?.rootViewController = mainTabBarController
        window?.makeKeyAndVisible()
    }

}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let lastOpenTabScreen = "selectedTabIndex"

    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        //guard let _ = (scene as? UIWindowScene) else { return }
        window?.tintColor  = AppStyle.appGlobalTintColor
        MediatorDelegate.configureRootViewController(window: window, sceneDelegate: self)
    }
    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
#if targetEnvironment(macCatalyst)
extension SceneDelegate: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == NSToolbarItem.Identifier(rawValue: "tabBarReplacement") {

            let group = NSToolbarItemGroup.init(itemIdentifier: NSToolbarItem.Identifier(rawValue: "tabBarReplacement"),
                                                titles: ["News Feed", "Campus", "Mensa", "Directory", "More"],
                                                selectionMode: .selectOne, labels: ["section1", "section2"], target: self, action: #selector(toolbarGroupSelectionChanged))
            // Load the last selected tab if the key exists in the UserDefaults
            if UserDefaults.standard.object(forKey: self.lastOpenTabScreen) != nil {
                let selectedIndex = UserDefaults.standard.integer(forKey: self.lastOpenTabScreen)
                group.setSelected(true, at: selectedIndex)
            } else {
                group.setSelected(true, at: 0)
            }
            return group
        }
        return nil
    }

    @objc func toolbarGroupSelectionChanged(sender: NSToolbarItemGroup) {
        print("tabBarReplacement selection changed to index: \(sender.selectedIndex)")

        let rootViewController = window?.rootViewController as? UITabBarController
        rootViewController?.selectedIndex = sender.selectedIndex
        // Save the selected index to the UserDefaults
        UserDefaults.standard.set(sender.selectedIndex, forKey: self.lastOpenTabScreen)
        UserDefaults.standard.synchronize()
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier(rawValue: "tabBarReplacement")]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
}
#endif
