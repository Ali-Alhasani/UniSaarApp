//
//  FilterMensaViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class FilterMensaViewControllerTests: XCTestCase {
    var viewControllerUnderTest: FilterMensaViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        self.viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "FilterMensaViewController") as? FilterMensaViewController
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
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.numberOfSections(in:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:numberOfRowsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.tableView(_:cellForRowAt:))))
    }
    func testTableViewCellHasReuseIdentifier() {
        if let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? FilterUISwitchTableViewCell {
            let actualReuseIdentifer = cell.reuseIdentifier
            let expectedReuseIdentifier = "FilterUISwitchTableViewCell"
            XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
        }

    }
    func testTableCellHasCorrectLabelText() {
        if let cell0 = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? FilterUISwitchTableViewCell {
            XCTAssertEqual(cell0.cellTitle, viewControllerUnderTest.filterMensaViewModel.filterList(for: .location)[safe: 0]?.filterName)
            XCTAssertEqual(cell0.switchValue, viewControllerUnderTest.filterMensaViewModel.filterList(for: .location)[safe: 0]?.isSelected)
        }
        let cell2 = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 2)) as? FilterUISwitchTableViewCell
        XCTAssertEqual(cell2?.cellTitle, viewControllerUnderTest.filterMensaViewModel.filterList(for: .allergenList)[safe: 0]?.filterName)
        XCTAssertEqual(cell2?.switchValue, viewControllerUnderTest.filterMensaViewModel.filterList(for: .location)[safe: 0]?.isSelected)
    }

}
