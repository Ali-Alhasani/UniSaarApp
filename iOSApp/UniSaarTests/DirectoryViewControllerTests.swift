//
//  DirectoryViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class DirectoryViewControllerTests: XCTestCase {

    var viewControllerUnderTest: DirectoryViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "DirectoryStoryboard", bundle: nil)
        self.viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "DirectoryViewControllerTest") as? DirectoryViewController

        self.viewControllerUnderTest.loadView()
        self.viewControllerUnderTest.viewDidLoad()
        self.viewControllerUnderTest.setupTableView()

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testHasATableView() {
        XCTAssertNotNil(viewControllerUnderTest.directoryTableView)
    }

    func testTableViewHasDelegate() {
        XCTAssertNotNil(viewControllerUnderTest.directoryTableView.delegate)
    }

    func testTableViewConfromsToTableViewDelegateProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDelegate.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:didSelectRowAt:))))
    }

    func testTableViewHasDataSource() {
        XCTAssertNotNil(viewControllerUnderTest.directoryTableView.dataSource)
    }

    func testTableViewConformsToTableViewDataSourceProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UITableViewDataSource.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:numberOfRowsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:cellForRowAt:))))
    }

    func testTableViewCellHasReuseIdentifier() {
        if let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.directoryTableView, cellForRowAt:
            IndexPath(row: 0, section: 0)) as? StaffSearchResultTableViewCell {
            let actualReuseIdentifer = cell.reuseIdentifier
            let expectedReuseIdentifier = "StaffSearchResultTableViewCell"
            XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
        } else if let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.directoryTableView, cellForRowAt:
            IndexPath(row: 0, section: 0)) as? HelpfulNumbersTableViewCell {
            let actualReuseIdentifer = cell.reuseIdentifier
            let expectedReuseIdentifier = "HelpfulNumbersTableViewCell"
            XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
        }
    }

    func testTableCellHasCorrectLabelText() {
        switch viewControllerUnderTest.directoryViewModel.helpfulNumbersCells.value[safe: 0] {
        case .normal(let cellViewModel):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.directoryTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? HelpfulNumbersTableViewCell
            XCTAssertEqual(cell?.textView.text, cellViewModel.fortmatedText)

        case .error(let message):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.directoryTableView, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, message)

        case .empty:
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.directoryTableView, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, NSLocalizedString("EmptyResults", comment: ""))
        case .none:
            break
        }
    }

    // utility for finding segues
    func hasSegueWithIdentifier(segueId: String) -> Bool {

        let segues = viewControllerUnderTest.value(forKey: "storyboardSegueTemplates") as? [NSObject]
        let filtered = segues?.filter({ $0.value(forKey: "identifier") as? String == segueId })

        return (filtered?.count ?? 0 > 0)
    }

    func testHasSegueForTransitioningToDetails() {
        let targetIdentifier = DirectoryViewController.SegueIdentifiers.toStaffDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))
    }

}
