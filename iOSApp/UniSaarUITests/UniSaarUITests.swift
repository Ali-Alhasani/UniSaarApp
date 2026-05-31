//
//  UniSaarUITests.swift
//  UniSaarUITests
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest

// @unchecked Sendable: XCTestCase (ObjC base) can't auto-derive Sendable, but
// @MainActor final class guarantees serialised access — the conformance is safe.
@MainActor
final class UniSaarUITests: XCTestCase, @unchecked Sendable {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        try super.setUpWithError()
        // XCTest calls lifecycle methods on the main thread — MainActor.assumeIsolated is safe here
        MainActor.assumeIsolated {
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
    }

    nonisolated override func tearDownWithError() throws {
        // XCTest calls lifecycle methods on the main thread — MainActor.assumeIsolated is safe here
        MainActor.assumeIsolated { app = nil }
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Taps through the first-launch campus selection screen if it is shown.
    @MainActor
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

    func testNewsFeedItemTapNavigatesToDetail() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["News Feed"].tap()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        // Wait for at least one real cell to load (not a loading/empty placeholder)
        let firstCell = table.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10), "At least one news cell should be present")
        firstCell.tap()
        // A back button in the nav bar confirms we navigated into a detail screen
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "A back button should appear after tapping a news item")
    }

    // MARK: - Mensa tab

    func testMensaTabShowsCollectionView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Mensa"].tap()
        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 5), "Mensa tab should show a collection view")
    }

    func testMensaNavigationBarHasFilterButton() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Mensa"].tap()
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Mensa nav bar should appear")
        // The gear / filter button sits in the nav bar trailing area
        XCTAssertGreaterThan(navBar.buttons.count, 0, "Mensa nav bar should have at least one button (filter/gear)")
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

    // MARK: - Campus tab

    func testCampusTabShowsMapView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Campus"].tap()
        XCTAssertTrue(app.maps.firstMatch.waitForExistence(timeout: 5), "Campus tab should present a map view")
    }

    // MARK: - More tab

    func testMoreTabShowsTableView() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["More"].tap()
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5), "More tab should show a table view")
    }

    func testMoreTabFirstItemIsSelectable() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["More"].tap()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        let firstCell = table.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "More tab should have at least one item")
        firstCell.tap()
        // After tapping, either a new screen pushes (back button appears) or a web view loads
        let didNavigate = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(didNavigate, "Tapping a More item should navigate to a detail screen")
    }

    // MARK: - Performance

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
