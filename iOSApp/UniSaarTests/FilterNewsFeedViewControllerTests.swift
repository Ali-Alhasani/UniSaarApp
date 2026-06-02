//
//  FilterNewsFeedViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
class FilterNewsFeedViewControllerTests: XCTestCase {
    var viewControllerUnderTest: FilterNewsFeedViewController!
    override func setUp() async throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "FilterNewsFeedViewController") as? FilterNewsFeedViewController
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
        XCTAssertNotNil(viewControllerUnderTest.filterTableView)
    }

    func testTableViewHasDelegate() {
        XCTAssertNotNil(viewControllerUnderTest.filterTableView.delegate)
    }

    func testTableViewConfromsToTableViewDelegateProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDelegate.self))
        // make sure that default selection is disabled ,only switches can have touch interaction
        //        XCTAssertFalse(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.filterTableView(_:didSelectRowAt:))))
    }

    func testTableViewHasDataSource() {
        XCTAssertNotNil(viewControllerUnderTest.filterTableView.dataSource)
    }

    func testTableViewConformsToTableViewDataSourceProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDataSource.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:numberOfRowsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:cellForRowAt:))))
    }

    func testTableViewCellHasReuseIdentifier() {
        let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? FilterUISwitchTableViewCell
        let actualReuseIdentifer = cell?.reuseIdentifier
        let expectedReuseIdentifier = "FilterUISwitchTableViewCell"
        XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
    }

    func testTableCellHasCorrectLabelText() {
        let cell0 = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? FilterUISwitchTableViewCell
        XCTAssertEqual(cell0?.cellTitle, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 0]?.name)
        XCTAssertEqual(cell0?.switchValue, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 0]?.isSelected)

        let cell1 = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 1, section: 0)) as? FilterUISwitchTableViewCell
        XCTAssertEqual(cell1?.cellTitle, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 1]?.name)

        XCTAssertEqual(cell1?.switchValue, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 1]?.isSelected)

        let cell2 = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 2, section: 0)) as? FilterUISwitchTableViewCell
        XCTAssertEqual(cell2?.cellTitle, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 2]?.name)
        XCTAssertEqual(cell2?.switchValue, viewControllerUnderTest.filterNewsViewModel.fetchedResultsController.fetchedObjects?[safe: 2]?.isSelected)
    }
}
