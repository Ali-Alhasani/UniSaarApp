//
//  FilterMensaViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

@MainActor
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
        // Section 0 (.location) returns a plain UITableViewCell (not FilterUISwitchTableViewCell); cast is expected to fail
        XCTAssertNil(
            viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? FilterUISwitchTableViewCell,
            "Location section uses a plain cell, not a switch cell"
        )
        // .allergenList is rawValue 3 (enum order: location=0, foodAlram=1, empty=2, allergenList=3)
        let allergenSection = FilterMensaViewModel.Filter.allergenList.rawValue
        let allergenItems = viewControllerUnderTest.filterMensaViewModel.filterList(for: .allergenList)
        guard !allergenItems.isEmpty else { return }
        let cell = viewControllerUnderTest.tableView(viewControllerUnderTest.filterTableView, cellForRowAt: IndexPath(row: 0, section: allergenSection)) as? FilterUISwitchTableViewCell
        XCTAssertEqual(cell?.cellTitle, allergenItems[safe: 0]?.filterName)
        XCTAssertEqual(cell?.switchValue, allergenItems[safe: 0]?.isSelected)
    }

}
