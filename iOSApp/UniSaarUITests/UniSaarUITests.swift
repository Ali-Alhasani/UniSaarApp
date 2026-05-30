//
//  UniSaarUITests.swift
//  UniSaarUITests
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest

final class UniSaarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()

        // Dismiss any system alerts (e.g. notification permission) automatically
        addUIInterruptionMonitor(withDescription: "System alert") { alert in
            let allow = alert.buttons["Allow"]
            if allow.exists { allow.tap(); return true }
            let ok = alert.buttons["OK"]
            if ok.exists { ok.tap(); return true }
            return false
        }

        app.launch()
        handleSetupScreenIfNeeded()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Taps through the first-launch campus selection screen if it is shown.
    private func handleSetupScreenIfNeeded() {
        let saarbruecken = app.buttons["Saarbrücken"]
        guard saarbruecken.waitForExistence(timeout: 3) else { return }
        saarbruecken.tap()
        app.buttons["Next"].tap()
        // Trigger the interruption monitor to handle the notification alert
        app.swipeUp()
    }

    private var tabBar: XCUIElement { app.tabBars.firstMatch }

    // MARK: - Tab bar structure

    func testTabBarIsPresent() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should be visible after launch")
    }

    func testTabBarHasFiveTabs() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertEqual(tabBar.buttons.count, 5, "App should have 5 tabs")
    }

    func testAllTabsAreReachable() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        let expectedTabs = ["News Feed", "Mensa", "Campus", "Directory", "More"]
        for tab in expectedTabs {
            XCTAssertTrue(tabBar.buttons[tab].exists, "Tab '\(tab)' should exist in the tab bar")
        }
    }

    // MARK: - News Feed tab

    func testNewsFeedTabShowsTableView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["News Feed"].tap()
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5), "News feed should show a table view")
    }

    // MARK: - Mensa tab

    func testMensaTabShowsCollectionView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Mensa"].tap()
        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 5), "Mensa tab should show a collection view")
    }

    // MARK: - Directory tab

    func testDirectoryTabShowsSearchBar() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Directory"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 3), "Directory tab should show a search bar")
    }

    func testDirectorySearchAcceptsInput() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Directory"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("Ali")
        XCTAssertEqual(searchField.value as? String, "Ali", "Search field should reflect typed text")
    }

    func testDirectorySearchCancelRestoresView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Directory"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("Ali")
        // The dismiss button label varies by locale and iOS version ("Cancel", "Abbrechen", "Close")
        let dismissButton = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Cancel", "Abbrechen", "Close", "Annuler"])
        ).firstMatch
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 3), "A dismiss button should appear while search is active")
        dismissButton.tap()
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Keyboard should be gone after dismissing search")
    }

    // MARK: - More tab

    func testMoreTabShowsTableView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["More"].tap()
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5), "More tab should show a table view")
    }

    // MARK: - Performance

    func testLaunchPerformance() {
        measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
            XCUIApplication().launch()
        }
    }
}
