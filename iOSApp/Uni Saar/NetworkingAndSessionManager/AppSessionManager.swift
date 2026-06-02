//
//  AppSessionManager.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

/// todo later
@MainActor
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
    var coordinateLastChanged: String = ""
    var isFoodAlarmEnabled: Bool = false
    var foodAlarmTime: Date?
    // to avoid fetchFilterListFromStorage more than one time in the run app run time
    var isMensaFiltersCacheFetched = false
    class var shared: AppSessionManager {
        struct Static {
            static let instance = AppSessionManager()
        }
        return Static.instance
    }

    // save the status of first opening setup screens, to not show it later
    static let skipWelcomeScreenKey = "skipWelcomeScreen"
    static let mensafiltersLastChangedKey = "mensafiltersLastChanged"
    static let newsFiltersLastChangedKey = "newsFiltersLastChanged"
    static let linksLastChangedKey = "linksLastChangedKey"
    static let helpfulNumbersLastChangedKey = "helpfulNumbersLastChanged"
    static let foodAlarmStatusKey = "foodAlarmStatusKey"
    static let foodAlarmTimeKey = "foodAlarmTimeKey"
    static let selectedCampusKey = "selectedCampusKey"
    static let selectedMensaLocationKey = "selectedMensaLocationKey"
}

/// cache functions
extension AppSessionManager {
    class func saveWelcomeScreenStatus() {
        let skipWelcomeScreen = AppSessionManager.shared.dismissWelcomeScreen
        UserDefaults.standard.set(skipWelcomeScreen, forKey: skipWelcomeScreenKey)
    }

    class func loadWelcomeScreenStatus() {
        AppSessionManager.shared.dismissWelcomeScreen = UserDefaults.standard.bool(forKey: skipWelcomeScreenKey)
    }

    class func saveMensafiltersStatus() {
        let mensafiltersLastChanged = AppSessionManager.shared.mensafiltersLastChanged
        UserDefaults.standard.set(mensafiltersLastChanged, forKey: mensafiltersLastChangedKey)
    }

    class func loadMensafiltersStatus() {
        guard let tempType = UserDefaults.standard.string(forKey: mensafiltersLastChangedKey) else { return }
        AppSessionManager.shared.mensafiltersLastChanged = tempType
    }

    class func saveNewsfiltersStatus() {
        let newsFiltersLastChanged = AppSessionManager.shared.newsFiltersLastChanged
        UserDefaults.standard.set(newsFiltersLastChanged, forKey: newsFiltersLastChangedKey)
    }

    class func loadNewsfiltersStatus() {
        guard let tempType = UserDefaults.standard.string(forKey: newsFiltersLastChangedKey) else { return }
        AppSessionManager.shared.newsFiltersLastChanged = tempType
    }

    class func saveMoreLinksStatus() {
        let morelinksLastChanged = AppSessionManager.shared.morelinksLastChanged
        UserDefaults.standard.set(morelinksLastChanged, forKey: linksLastChangedKey)
    }

    class func loadMoreLinksStatus() {
        guard let tempType = UserDefaults.standard.string(forKey: linksLastChangedKey) else { return }
        AppSessionManager.shared.morelinksLastChanged = tempType
    }

    class func saveHelpfulNumberStatus() {
        let helpfulNumbersLastChange = AppSessionManager.shared.helpfulNumbersLastChanged
        UserDefaults.standard.set(helpfulNumbersLastChange, forKey: helpfulNumbersLastChangedKey)
    }

    class func loadHelpfulNumberStatus() {
        guard let tempType = UserDefaults.standard.string(forKey: helpfulNumbersLastChangedKey) else { return }
        AppSessionManager.shared.helpfulNumbersLastChanged = tempType
    }

    class func saveFoodAlarmStatus() {
        let foodAlarmStatus = AppSessionManager.shared.isFoodAlarmEnabled
        UserDefaults.standard.set(foodAlarmStatus, forKey: foodAlarmStatusKey)

        let foodAlarmTime = AppSessionManager.shared.foodAlarmTime
        UserDefaults.standard.set(foodAlarmTime, forKey: foodAlarmTimeKey)
    }

    class func loadFoodAlarmTime() {
        AppSessionManager.shared.isFoodAlarmEnabled = UserDefaults.standard.bool(forKey: foodAlarmStatusKey)
        AppSessionManager.shared.foodAlarmTime = UserDefaults.standard.object(forKey: foodAlarmTimeKey) as? Date
    }

    class func saveCampuslocation() {
        let campuslocation = AppSessionManager.shared.selectedCampus.locationKey
        UserDefaults.standard.set(campuslocation, forKey: selectedCampusKey)

        let mensaLocation = AppSessionManager.shared.selectedMensaLocation.locationKey
        UserDefaults.standard.set(mensaLocation, forKey: selectedMensaLocationKey)
    }

    class func loadCampuslocation() {
        guard let campuslocation = UserDefaults.standard.string(forKey: selectedCampusKey) else { return }
        AppSessionManager.shared.selectedCampus = Campus(rawValue: campuslocation) ?? .saarbruken

        guard let mensaLocation = UserDefaults.standard.string(forKey: selectedMensaLocationKey) else { return }
        AppSessionManager.shared.selectedMensaLocation = Campus(rawValue: mensaLocation) ?? .saarbruken
        notifyCampusView()
    }

    class func notifyCampusView() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CampusSettingsDidUpdate"), object: nil)
    }
}
