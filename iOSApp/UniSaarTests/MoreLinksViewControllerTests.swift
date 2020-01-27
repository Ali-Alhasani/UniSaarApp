//
//  MoreLinksViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class MoreLinksViewControllerTests: XCTestCase {
    var viewControllerUnderTest: MoreLinksViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "MoreLinksStoryboard", bundle: nil)
        self.viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "MoreViewController") as? MoreLinksViewController
        self.viewControllerUnderTest.loadView()
        self.viewControllerUnderTest.viewDidLoad()
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
        switch viewControllerUnderTest.moreLinksViewModel.linksCells.value[safe: 0] {
        case .normal(let cellViewModel):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, cellViewModel.nameText)

        case .error(let message):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, message)

        case .empty:
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
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
        let targetIdentifier = MoreLinksViewController.SegueIdentifiers.toLinkDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))

        let targetIdentifier2 = MoreLinksViewController.SegueIdentifiers.toSettings
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier2))

        let targetIdentifier3 = MoreLinksViewController.SegueIdentifiers.toAboutApp
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier3))
    }
}
