//
//  MoreViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import SwiftyJSON
@testable import Uni_Saar
import XCTest

@MainActor
final class MoreViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Prevent CoreData pre-load so mock network responses control cell state
        AppSessionManager.shared.morelinksLastChanged = "never"
    }

    override func tearDown() {
        AppSessionManager.shared.morelinksLastChanged = "never"
        super.tearDown()
    }

    func testMoreLinksModel() {
        let testSuccessfulJSON = MoreLinksModel.deomJSON
        let formattedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(MoreLinksModel(json: formattedJSON, index: 0))
    }

    func testNormalMoreLinksCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(MoreModel.demoData)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        await viewModel.loadGetMoreLinks()
        guard case .normal = viewModel.linksCells.first else {
            XCTFail("More Links should have value")
            return
        }
    }

    func testEmptyMoreLinksCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .success(MoreModel(json: [:]))
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        await viewModel.loadGetMoreLinks()
        XCTAssertTrue(viewModel.linksCells.isEmpty, "More Links Cell should be empty")
    }

    func testErrorMoreLinksCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMoreLinksResult = .failure(AppError.networkFailure)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        await viewModel.loadGetMoreLinks()
        if case .error = viewModel.linksCells.first {
            return
        }
        guard viewModel.fetchedResultsController.fetchedObjects?.count == 0 else {
            XCTFail("More Links should be in failed")
            return
        }
    }

    func testMoreLinksViewModelValues() async {
        let dataClient = MockAppDataClient()
        let moreLinksResults = MoreModel.demoData
        dataClient.getMoreLinksResult = .success(moreLinksResults)
        let viewModel = MoreLinksViewModel(dataClient: dataClient)
        await viewModel.loadGetMoreLinks()
        switch viewModel.linksCells.first {
        case let .normal(cellViewModel):
            let linkItem = moreLinksResults.links.first
            XCTAssertEqual(linkItem?.displayName, cellViewModel.nameText)
            XCTAssertEqual(URL(string: linkItem?.url ?? ""), cellViewModel.linkURL)
        case let .error(message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
