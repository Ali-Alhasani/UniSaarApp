//
//  MoreLinksViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
class MoreLinksViewControllerTests: XCTestCase {
    var viewControllerUnderTest: MoreLinksViewController!
    override func setUp() async throws {
        let storyboard = UIStoryboard(name: "MoreLinksStoryboard", bundle: nil)
        viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "MoreViewController") as? MoreLinksViewController
        viewControllerUnderTest.loadView()
        viewControllerUnderTest.viewDidLoad()
    }

    override func tearDown() {
        viewControllerUnderTest = nil
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testHasATableView() {
        XCTAssertNotNil(viewControllerUnderTest.tableView)
    }

    func testTableViewHasDelegate() {
        XCTAssertNotNil(viewControllerUnderTest.tableView.delegate)
    }

    func testTableViewConfromsToTableViewDelegateProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDelegate.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:didSelectRowAt:))))
    }

    func testTableViewHasDataSource() {
        XCTAssertNotNil(viewControllerUnderTest.tableView.dataSource)
    }

    func testTableViewConformsToTableViewDataSourceProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDataSource.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.numberOfSections(in:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:numberOfRowsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:cellForRowAt:))))
    }

    func testTableViewCellHasReuseIdentifier() {
        let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 1))
        let actualReuseIdentifer = cell.reuseIdentifier
        let expectedReuseIdentifier = "moreLinksCell"
        XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
    }

    func testTableCellHasCorrectLabelText() {
        switch viewControllerUnderTest.moreLinksViewModel.linksCells[safe: 0] {
        case let .normal(cellViewModel):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            let config = cell.contentConfiguration as? UIListContentConfiguration
            XCTAssertEqual(config?.text, cellViewModel.nameText)

        case let .error(message):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            let config = cell.contentConfiguration as? UIListContentConfiguration
            XCTAssertEqual(config?.text, message)

        case .empty:
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            let config = cell.contentConfiguration as? UIListContentConfiguration
            XCTAssertEqual(config?.text, String(localized: "EmptyResults"))

        case .none:
            break
        }
    }

    /// utility for finding segues
    func hasSegueWithIdentifier(segueId: String) -> Bool {
        let segues = viewControllerUnderTest.value(forKey: "storyboardSegueTemplates") as? [NSObject]
        let filtered = segues?.filter { $0.value(forKey: "identifier") as? String == segueId }

        return (filtered?.count ?? 0 > 0)
    }

    func testHasSegueForTransitioningToDetails() {
        let targetIdentifier = MoreLinksViewController.SegueIdentifiers.toLinkDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))

        let targetIdentifier2 = MoreLinksViewController.SegueIdentifiers.toSettings
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier2))

        let targetIdentifier3 = MoreLinksViewController.SegueIdentifiers.toAboutApp
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier3))
    }
}
