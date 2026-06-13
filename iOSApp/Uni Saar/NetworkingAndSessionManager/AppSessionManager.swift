//
//  AppSessionManager.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
class AppSessionManager {
    static let shared = AppSessionManager()

    // MARK: - Persisted

    var dismissWelcomeScreen: Bool {
        didSet { defaults.set(dismissWelcomeScreen, forKey: Self.skipWelcomeScreenKey) }
    }
    var selectedCampus: Campus {
        didSet { defaults.set(selectedCampus.rawValue, forKey: Self.selectedCampusKey) }
    }
    var selectedMensaLocation: Campus {
        didSet { defaults.set(selectedMensaLocation.rawValue, forKey: Self.selectedMensaLocationKey) }
    }
    var mensafiltersLastChanged: String? {
        didSet { defaults.set(mensafiltersLastChanged, forKey: Self.mensafiltersLastChangedKey) }
    }
    var newsFiltersLastChanged: String? {
        didSet { defaults.set(newsFiltersLastChanged, forKey: Self.newsFiltersLastChangedKey) }
    }
    var morelinksLastChanged: String {
        didSet { defaults.set(morelinksLastChanged, forKey: Self.linksLastChangedKey) }
    }
    var helpfulNumbersLastChanged: String {
        didSet { defaults.set(helpfulNumbersLastChanged, forKey: Self.helpfulNumbersLastChangedKey) }
    }
    var isFoodAlarmEnabled: Bool {
        didSet { defaults.set(isFoodAlarmEnabled, forKey: Self.foodAlarmStatusKey) }
    }
    var foodAlarmTime: Date? {
        didSet { defaults.set(foodAlarmTime, forKey: Self.foodAlarmTimeKey) }
    }

    // MARK: - Session-only (reset each launch)

    var isMensaFiltersCacheFetched = false

    // MARK: - Private

    @ObservationIgnored private let defaults: UserDefaults

    private static let skipWelcomeScreenKey = "skipWelcomeScreen"
    private static let selectedCampusKey = "selectedCampusKey"
    private static let selectedMensaLocationKey = "selectedMensaLocationKey"
    private static let mensafiltersLastChangedKey = "mensafiltersLastChanged"
    private static let newsFiltersLastChangedKey = "newsFiltersLastChanged"
    private static let linksLastChangedKey = "linksLastChangedKey"
    private static let helpfulNumbersLastChangedKey = "helpfulNumbersLastChanged"
    private static let foodAlarmStatusKey = "foodAlarmStatusKey"
    private static let foodAlarmTimeKey = "foodAlarmTimeKey"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dismissWelcomeScreen = defaults.bool(forKey: Self.skipWelcomeScreenKey)
        selectedCampus = Campus(rawValue: defaults.string(forKey: Self.selectedCampusKey) ?? "") ?? .saarbruken
        selectedMensaLocation = Campus(rawValue: defaults.string(forKey: Self.selectedMensaLocationKey) ?? "") ?? .saarbruken
        mensafiltersLastChanged = defaults.string(forKey: Self.mensafiltersLastChangedKey)
        newsFiltersLastChanged = defaults.string(forKey: Self.newsFiltersLastChangedKey)
        morelinksLastChanged = defaults.string(forKey: Self.linksLastChangedKey) ?? "never"
        helpfulNumbersLastChanged = defaults.string(forKey: Self.helpfulNumbersLastChangedKey) ?? "never"
        isFoodAlarmEnabled = defaults.bool(forKey: Self.foodAlarmStatusKey)
        foodAlarmTime = defaults.object(forKey: Self.foodAlarmTimeKey) as? Date
    }
}
