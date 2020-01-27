//
//  MensaViewControllerTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class MensaViewControllerTests: XCTestCase {
    var viewControllerUnderTest: MensaViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        self.viewControllerUnderTest = storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as? MensaViewController

        self.viewControllerUnderTest.loadView()
        self.viewControllerUnderTest.viewDidLoad()
        self.viewControllerUnderTest.setupCollectionView()
    }
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    func testHasACollectionView() {
        XCTAssertNotNil(viewControllerUnderTest.mensaCollectionView)
    }
    func testCollectionViewHasDelegate() {
        XCTAssertNotNil(viewControllerUnderTest.mensaCollectionView.delegate)
    }
    func testCollectionViewConfromsToTableViewDelegateProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UICollectionViewDelegate.self))
    }
    func testCollectionViewHasDataSource() {
        XCTAssertNotNil(viewControllerUnderTest.mensaCollectionView.dataSource)
    }
    func testCollectionViewConformsToCollectionViewDataSourceProtocol() {
        XCTAssertTrue(viewControllerUnderTest.conforms(to: UICollectionViewDataSource.self))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.collectionView(_:numberOfItemsInSection:))))
        XCTAssertTrue(viewControllerUnderTest.responds(to: #selector(viewControllerUnderTest.collectionView(_:cellForItemAt:))))
    }
    func testCollectionViewCellHasReuseIdentifier() {
        if let cell = viewControllerUnderTest.collectionView(viewControllerUnderTest.mensaCollectionView, cellForItemAt:
            IndexPath(item: 0, section: 0)) as? MensaCollectionViewCell {
            let actualReuseIdentifer = cell.reuseIdentifier
            let expectedReuseIdentifier = "MensaCollectionViewCell"
            XCTAssertEqual(actualReuseIdentifer, expectedReuseIdentifier)
        }
    }

    func testCollectionViewHasCorrectLabelText() {
        switch viewControllerUnderTest.mensaMenuViewModel.daysMenus.value[safe: 0] {
        case .normal:
            XCTAssertNotNil(viewControllerUnderTest.collectionView(viewControllerUnderTest.mensaCollectionView, cellForItemAt:
                IndexPath(item: 0, section: 0)) as? MensaCollectionViewCell)
        case .error(let message):
            let cell = viewControllerUnderTest.collectionView(viewControllerUnderTest.mensaCollectionView, cellForItemAt:
                IndexPath(item: 0, section: 0)) as? ErrorCellCollectionViewCell
            XCTAssertEqual(cell?.text, message)
        case .empty:
            let cell = viewControllerUnderTest.collectionView(viewControllerUnderTest.mensaCollectionView, cellForItemAt:
                IndexPath(item: 0, section: 0)) as? ErrorCellCollectionViewCell
            XCTAssertEqual(cell?.text, NSLocalizedString("emptyMenu", comment: "no menu"))
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
        let targetIdentifier = MensaViewController.SegueIdentifiers.toMealDetails
        XCTAssertTrue(hasSegueWithIdentifier(segueId: targetIdentifier))
    }

}
