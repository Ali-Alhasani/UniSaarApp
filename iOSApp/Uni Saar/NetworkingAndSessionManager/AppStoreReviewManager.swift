//
//  AppStoreReviewManager.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 11/25/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import StoreKit

enum AppStoreReviewManager {
    static let minimumReviewWorthyActionCount = 5
    static let appVersion = "2.1"

    static func requestReviewIfAppropriate(presentedView: UIViewController) {

        let defaults = UserDefaults.standard
        let today = Date().timeIntervalSince1970

        let lastDate = defaults.double(forKey: .lastOpenDate)
        if let lastDate = lastDate {
            // print("The app was first opened on \(lastOpenDate)")
            //86400 number of seconds in a day
            if lastDate + 86400  > today {
                return
            }
        }
        // This is the last launch
        defaults.set(today, forKey: .lastOpenDate)

        var actionCount = defaults.integer(forKey: .reviewWorthyActionCount)
        actionCount += 1
        defaults.set(actionCount, forKey: .reviewWorthyActionCount)
        //open the app reivew after minimumReviewWorthyActionCount times
        guard actionCount >= minimumReviewWorthyActionCount else {
            return
        }

        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? appVersion
        let lastVersion = defaults.string(forKey: .lastReviewRequestAppVersions)

        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }

        let alert = ratingDialogHandler { _ in
            SKStoreReviewController.requestReview()
        }

        presentedView.present(alert, animated: true)

        defaults.set(0, forKey: .reviewWorthyActionCount)
        defaults.set(currentVersion, forKey: .lastReviewRequestAppVersions)

    }

    static func ratingDialogHandler(_ succesHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("RateTitle", comment: ""), message: NSLocalizedString("EnjoyingAPP", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("RateYesActionTitle", comment: ""), style: .default, handler: succesHandler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("RateNoActionTitle", comment: ""), style: .cancel, handler: nil))
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
        return integer(forKey: key.rawValue)
    }

    func string(forKey key: Key) -> String? {
        return string(forKey: key.rawValue)
    }

    func double(forKey key: Key) -> Double? {
        return double(forKey: key.rawValue)
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
