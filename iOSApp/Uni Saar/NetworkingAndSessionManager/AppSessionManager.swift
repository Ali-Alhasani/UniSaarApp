//
//  AppSessionManager.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
//todo later
class AppSessionManager {
    var dismissWelcomeScreen: Bool = false
    var selectedCampus: Campus = .saarbruken
    var selectedMensaLocation: Campus = .saarbruken
    var isEventEnabled = false
    // api last updated date
    var mensafiltersLastChanged: String?
    var newsFiltersLastChanged: String?
    var morelinksLastChanged: String = "never"
    var helpfulNumbersLastChanged: String = "never"
    // to avoid fetchFilterListFromStorage more than one time in the run app run time
    var isMensaFiltersCacheFetched = false
    class var shared: AppSessionManager {
        struct Static {
            static let instance = AppSessionManager()
        }
        return Static.instance
    }
    //save the status of first opening setup screens, to not show it later
    static let skipWelcomeScreenKey = "skipWelcomeScreen"
    static let mensafiltersLastChangedKey = "mensafiltersLastChanged"
    static let newsFiltersLastChangedKey = "newsFiltersLastChanged"
    static let linksLastChangedKey = "skipWelcomeScreen"
    static let helpfulNumbersLastChangedKey = "helpfulNumbersLastChanged"

}
// cache functions
extension AppSessionManager {
   class func saveWelcomeScreenStatus() {
        let skipWelcomeScreen =  AppSessionManager.shared.dismissWelcomeScreen
        UserDefaults.standard.set(skipWelcomeScreen, forKey: skipWelcomeScreenKey)
    }
    class func loadWelcomeScreenStatus() {
        guard let tempType = UserDefaults.standard.value(forKey: skipWelcomeScreenKey) as? Bool else {return}
        AppSessionManager.shared.dismissWelcomeScreen = tempType
    }
    class func saveMensafiltersStatus() {
        let mensafiltersLastChanged =  AppSessionManager.shared.mensafiltersLastChanged
        UserDefaults.standard.set(mensafiltersLastChanged, forKey: mensafiltersLastChangedKey)
    }
    class func loadMensafiltersStatus() {
        guard let tempType = UserDefaults.standard.value(forKey: mensafiltersLastChangedKey) as? String else {return}
        AppSessionManager.shared.mensafiltersLastChanged = tempType
    }
    class func saveNewsfiltersStatus() {
        let newsFiltersLastChanged =  AppSessionManager.shared.newsFiltersLastChanged
        UserDefaults.standard.set(newsFiltersLastChanged, forKey: newsFiltersLastChangedKey)
    }
    class func loadNewsfiltersStatus() {
        guard let tempType = UserDefaults.standard.value(forKey: newsFiltersLastChangedKey) as? String else {return}
        AppSessionManager.shared.newsFiltersLastChanged = tempType
    }

    class func saveMoreLinksStatus() {
        let morelinksLastChanged =  AppSessionManager.shared.morelinksLastChanged
        UserDefaults.standard.set(morelinksLastChanged, forKey: linksLastChangedKey)
    }
    class func loadMoreLinksStatus() {
        guard let tempType = UserDefaults.standard.value(forKey: linksLastChangedKey) as? String else {return}
        AppSessionManager.shared.morelinksLastChanged = tempType
    }

    class func saveHelpfulNumberStatus() {
          let helpfulNumbersLastChanged =  AppSessionManager.shared.helpfulNumbersLastChanged
          UserDefaults.standard.set(helpfulNumbersLastChanged, forKey: helpfulNumbersLastChangedKey)
      }
      class func loadHelpfulNumberStatus() {
          guard let tempType = UserDefaults.standard.value(forKey: helpfulNumbersLastChangedKey) as? String else {return}
          AppSessionManager.shared.helpfulNumbersLastChanged = tempType
      }
}
