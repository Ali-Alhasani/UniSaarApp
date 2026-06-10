//
//  NewsFeedViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
class NewsFeedViewControllerTests: XCTestCase {
    var viewControllerUnderTest: NewsFeedViewController!
    override func setUp() async throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController
        viewControllerUnderTest.loadView()
        viewControllerUnderTest.viewDidLoad()
        viewControllerUnderTest.setupTableView()
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
        XCTAssertNotNil(viewControllerUnderTest.newsTable)
    }

    func testTableViewHasDelegate() {
        XCTAssertNotNil(viewControllerUnderTest.newsTable.delegate)
    }

    func testTableViewConfromsToTableViewDelegateProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDelegate.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:didSelectRowAt:))))
    }

    func testTableViewHasDataSource() {
        XCTAssertNotNil(viewControllerUnderTest.newsTable.dataSource)
    }

    func testTableViewConformsToTableViewDataSourceProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDataSource.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:numberOfRowsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:cellForRowAt:))))
    }

    func testTableViewCellHasReuseIdentifier() {
        if let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0)) as? NewsFeedTableViewCell {
            let actualReuseIdentifer = cell.reuseIdentifier
            let expectedReuseIdentifier = "NewsFeedTableViewCell"
            XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
        }
    }

    func testTableCellHasCorrectLabelText() {
        switch viewControllerUnderTest.newsViewModel.newsCells[safe: 0] {
        case let .normal(cellViewModel):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0)) as? NewsFeedTableViewCell
            XCTAssertEqual(cell?.newsTitleLabel.text, cellViewModel.titleText)

        case let .error(message):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0))
            let config = cell.contentConfiguration as? UIListContentConfiguration
            XCTAssertEqual(config?.text, message)

        case .empty:
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0))
            let config = cell.contentConfiguration as? UIListContentConfiguration
            XCTAssertEqual(config?.text, NSLocalizedString("EmptyNews", comment: ""))

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
        let targetIdentifier = NewsFeedViewController.SegueIdentifiers.toNewsDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))

        let targetIdentifier2 = NewsFeedViewController.SegueIdentifiers.toEventDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier2))
    }
}
