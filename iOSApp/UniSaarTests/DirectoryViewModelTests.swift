//
//  DirectoryViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import Uni_Saar

@MainActor
final class DirectoryViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Prevent CoreData pre-load so mock network responses control cell state
        AppSessionManager.shared.helpfulNumbersLastChanged = "never"
    }

    override func tearDown() {
        AppSessionManager.shared.helpfulNumbersLastChanged = "never"
        super.tearDown()
    }

    // MARK: - Staff search

    func testDirectoryModel() {
        let testSuccessfulJSON = StaffModel.deomJSON
        XCTAssertNotNil(StaffModel(json: testSuccessfulJSON))
    }

    func testNormalDirectoryCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(StaffModel.staffDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetSearchResults(searchQuery: "Ali")
        guard case .normal(_) = viewModel.searchResutlsCells.first else {
            XCTFail("Directory should have value")
            return
        }
    }

    func testEmptyDirectoryCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(StaffModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetSearchResults(searchQuery: "")
        guard case .empty = viewModel.searchResutlsCells.first else {
            XCTFail("Directory Cell should be empty")
            return
        }
    }

    func testErrorDirectoryCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetSearchResults(searchQuery: "")
        guard case .error(_) = viewModel.searchResutlsCells.first else {
            XCTFail("Directory should be in failed")
            return
        }
    }

    func testDirectoryViewModelValues() async {
        let dataClient = MockAppDataClient()
        let staffResults = StaffModel.staffDemoData
        dataClient.getSearchDirectoryResult = .success(staffResults)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetSearchResults(searchQuery: "Ali")
        switch viewModel.searchResutlsCells.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(staffResults.staffResults.first?.fullName, cellViewModel.nameText)
            XCTAssertEqual(staffResults.staffResults.first?.title, cellViewModel.titleText)
            XCTAssertEqual(staffResults.staffResults.first?.staffID, cellViewModel.staffId)
        case .error(let message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }

    // MARK: - Helpful numbers

    func testHelpfulNumberModel() {
        let testSuccessfulJSON = NumberModel.deomJSON
        let formattedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(NumberModel(json: formattedJSON))
    }

    func testNormalHelpfulNumberCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(HelpfulNumbersModel.helpfulNumbersDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetHelpHelpfulNumbers()
        guard case .normal(_) = viewModel.helpfulNumbersCells.first else {
            XCTFail("Helpful Numbers should have value")
            return
        }
    }

    func testEmptyHelpfulCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(HelpfulNumbersModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetHelpHelpfulNumbers()
        XCTAssertTrue(viewModel.helpfulNumbersCells.isEmpty, "Helpful Numbers Cell should be empty")
    }

    func testErrorHelpfulNumberCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetHelpHelpfulNumbers()
        guard case .error(_) = viewModel.helpfulNumbersCells.first else {
            XCTFail("Helpful Numbers should be in failed")
            return
        }
    }

    func testHelpfulNumberViewModelValues() async {
        let dataClient = MockAppDataClient()
        let helpfulNumberResults = HelpfulNumbersModel.helpfulNumbersDemoData
        dataClient.getHelpfulNumbersResult = .success(helpfulNumberResults)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        await viewModel.loadGetHelpHelpfulNumbers()
        switch viewModel.helpfulNumbersCells.first {
        case .normal(let cellViewModel):
            let numberItem = helpfulNumberResults.numbers.first
            var itemFormatted = (numberItem!.name ?? "") + "\n" + (numberItem!.number ?? "") + "\n"
            itemFormatted += (numberItem!.link ?? "") + "\n" + (numberItem!.mail ?? "")
            XCTAssertEqual(itemFormatted, cellViewModel.fortmatedText)
        case .error(let message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
