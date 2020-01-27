//
//  NewsFeedViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class NewsFeedViewControllerTests: XCTestCase {
    var viewControllerUnderTest: NewsFeedViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        self.viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController

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
        switch viewControllerUnderTest.newsViewModel.newsCells.value[safe: 0] {
        case .normal(let cellViewModel):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0)) as? NewsFeedTableViewCell
            XCTAssertEqual(cell?.newsTitleLabel.text, cellViewModel.titleText)

        case .error(let message):
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, message)

        case .empty:
            let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.newsTable, cellForRowAt: IndexPath(row: 0, section: 0))
            XCTAssertEqual(cell.textLabel?.text, NSLocalizedString("EmptyNews", comment: ""))
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
          let targetIdentifier = NewsFeedViewController.SegueIdentifiers.toNewsDetails
          XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))

          let targetIdentifier2 = NewsFeedViewController.SegueIdentifiers.toEventDetails
          XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier2))
      }
}
