//
//  MoreViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar
import SwiftyJSON
class MoreViewModelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func testMoreLinksModel() {
        let testSuccessfulJSON = MoreLinksModel.deomJSON
        let foramtedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(MoreLinksModel(json: foramtedJSON))
    }
    func testNormalMoreLinksCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(payload: MoreModel.demoData)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        viewModel.loadGetMoreLinks()
        guard case .some(.normal(_)) = viewModel.linksCells.value.first else {
            XCTFail("More Links should have value")
            return
        }
    }
    func testEmptyHelpfulCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(payload: MoreModel(json: [:]))
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        viewModel.loadGetMoreLinks()
        guard viewModel.linksCells.value.count == 0 else {
            XCTFail("More Links Cell should be empty")
            return
        }
    }
    func testErrorMoreLinksCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .failure(MyError.customError)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        viewModel.loadGetMoreLinks()
        guard case .some(.error(_)) = viewModel.linksCells.value.first else {
            if viewModel.fetchedResultsController.fetchedObjects?.count == 0 {
                return
            }
            XCTFail("More Links should be in faild")
            return
        }
    }
    func testMoreLinksViewModelValues() {

        let dataClient = MockAppDataClient()
        let moreLinksResutls = MoreModel.demoData
        dataClient.getMoreLinksResult = .success(payload: moreLinksResutls)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        viewModel.loadGetMoreLinks()
        switch viewModel.linksCells.value.first {
        case .normal(let cellViewModel):
            let linkItem = moreLinksResutls.links.first
            XCTAssertEqual(linkItem?.displayName, cellViewModel.nameText)
            XCTAssertEqual(URL(string: linkItem?.url ?? ""), cellViewModel.linkURL)

        case .some(.error(let message)):
            XCTAssertNotNil(message)
        case .some(.empty):
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
