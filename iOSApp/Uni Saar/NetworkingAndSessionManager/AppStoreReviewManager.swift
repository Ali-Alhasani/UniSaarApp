//
//  AppStoreReviewManager.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 11/25/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import StoreKit
import UIKit

enum AppStoreReviewManager {
    static let minimumReviewWorthyActionCount = 5
    static let appVersion = "2.1"

    @MainActor
    static func requestReviewIfAppropriate(presentedView: UIViewController) {
        let defaults = UserDefaults.standard
        let today = Date().timeIntervalSince1970

        let lastDate = defaults.double(forKey: .lastOpenDate)
        if let lastDate {
            // print("The app was first opened on \(lastOpenDate)")
            // 86400 number of seconds in a day
            if lastDate + 86400 > today {
                return
            }
        }
        // This is the last launch
        defaults.set(today, forKey: .lastOpenDate)

        var actionCount = defaults.integer(forKey: .reviewWorthyActionCount)
        actionCount += 1
        defaults.set(actionCount, forKey: .reviewWorthyActionCount)
        // open the app reivew after minimumReviewWorthyActionCount times
        guard actionCount >= minimumReviewWorthyActionCount else {
            return
        }

        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? appVersion
        let lastVersion = defaults.string(forKey: .lastReviewRequestAppVersions)

        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }

        let alert = ratingDialogHandler { _ in
            Task { @MainActor in
                if let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    AppStore.requestReview(in: windowScene)
                }
            }
        }

        presentedView.present(alert, animated: true)

        defaults.set(0, forKey: .reviewWorthyActionCount)
        defaults.set(currentVersion, forKey: .lastReviewRequestAppVersions)
    }

    @MainActor
    static func ratingDialogHandler(_ succesHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: String(localized: "RateTitle"), message: String(localized: "EnjoyingAPP"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "RateYesActionTitle"), style: .default, handler: succesHandler))
        alert.addAction(UIAlertAction(title: String(localized: "RateNoActionTitle"), style: .cancel, handler: nil))
        return alert
    }
}

extension UserDefaults {
    enum Key: String {
        case reviewWorthyActionCount
        case lastReviewRequestAppVersions
        case lastOpenDate
    }

    func integer(forKey key: Key) -> Int {
        integer(forKey: key.rawValue)
    }

    func string(forKey key: Key) -> String? {
        string(forKey: key.rawValue)
    }

    func double(forKey key: Key) -> Double? {
        double(forKey: key.rawValue)
    }

    func set(_ integer: Int, forKey key: Key) {
        set(integer, forKey: key.rawValue)
    }

    func set(_ timeInterval: Double, forKey key: Key) {
        set(timeInterval, forKey: key.rawValue)
    }

    func set(_ object: Any?, forKey key: Key) {
        set(object, forKey: key.rawValue)
    }
}
