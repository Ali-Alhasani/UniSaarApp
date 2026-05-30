//
//  MoreViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
import Combine
import SwiftyJSON
@testable import Uni_Saar

@MainActor
class MoreViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        // Prevent CoreData pre-load so mock network responses control cell state
        AppSessionManager.shared.morelinksLastChanged = "never"
    }

    override func tearDown() {
        AppSessionManager.shared.morelinksLastChanged = "never"
        cancellables.removeAll()
        super.tearDown()
    }

    func testMoreLinksModel() {
        let testSuccessfulJSON = MoreLinksModel.deomJSON
        let formattedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(MoreLinksModel(json: formattedJSON, index: 0))
    }

    func testNormalMoreLinksCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(MoreModel.demoData)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)

        let exp = expectation(description: "linksCells updated")
        viewModel.$linksCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMoreLinks()
        waitForExpectations(timeout: 1.0)

        guard case .normal(_) = viewModel.linksCells.first else {
            XCTFail("More Links should have value")
            return
        }
    }

    func testEmptyMoreLinksCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(MoreModel(json: [:]))
        let viewModel = MoreLinksViewModel(dataClient: dataClient)

        // Empty network response doesn't update linksCells; wait for loading to finish instead
        let exp = expectation(description: "load completes")
        viewModel.$showLoadingIndicator.dropFirst().filter { !$0 }.sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMoreLinks()
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(viewModel.linksCells.isEmpty, "More Links Cell should be empty")
    }

    func testErrorMoreLinksCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .failure(MyError.customError)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)

        let exp = expectation(description: "linksCells updated")
        viewModel.$linksCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMoreLinks()
        waitForExpectations(timeout: 1.0)

        if case .error(_) = viewModel.linksCells.first {
            return
        }
        guard viewModel.fetchedResultsController.fetchedObjects?.count == 0 else {
            XCTFail("More Links should be in failed")
            return
        }
    }

    func testMoreLinksViewModelValues() {
        let dataClient = MockAppDataClient()
        let moreLinksResults = MoreModel.demoData
        dataClient.getMoreLinksResult = .success(moreLinksResults)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)

        let exp = expectation(description: "linksCells updated")
        viewModel.$linksCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMoreLinks()
        waitForExpectations(timeout: 1.0)

        switch viewModel.linksCells.first {
        case .normal(let cellViewModel):
            let linkItem = moreLinksResults.links.first
            XCTAssertEqual(linkItem?.displayName, cellViewModel.nameText)
            XCTAssertEqual(URL(string: linkItem?.url ?? ""), cellViewModel.linkURL)
        case .error(let message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
