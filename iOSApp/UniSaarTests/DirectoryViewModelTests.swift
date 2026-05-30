//
//  DirectoryViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
import Combine
import SwiftyJSON
@testable import Uni_Saar

@MainActor
class DirectoryViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        // Prevent CoreData pre-load so mock network responses control cell state
        AppSessionManager.shared.helpfulNumbersLastChanged = "never"
    }

    override func tearDown() {
        AppSessionManager.shared.helpfulNumbersLastChanged = "never"
        cancellables.removeAll()
        super.tearDown()
    }

    func testDirectoryModel() {
        let testSuccessfulJSON = StaffModel.deomJSON
        XCTAssertNotNil(StaffModel(json: testSuccessfulJSON))
    }

    func testNormalDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(StaffModel.staffDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "searchResutlsCells updated")
        viewModel.$searchResutlsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetSearchResults(searchQuery: "Ali")
        waitForExpectations(timeout: 1.0)

        guard case .normal(_) = viewModel.searchResutlsCells.first else {
            XCTFail("Directory should have value")
            return
        }
    }

    func testEmptyDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(StaffModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "searchResutlsCells updated")
        viewModel.$searchResutlsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetSearchResults(searchQuery: "")
        waitForExpectations(timeout: 1.0)

        guard case .empty = viewModel.searchResutlsCells.first else {
            XCTFail("Directory Cell should be empty")
            return
        }
    }

    func testErrorDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "searchResutlsCells updated")
        viewModel.$searchResutlsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetSearchResults(searchQuery: "")
        waitForExpectations(timeout: 1.0)

        guard case .error(_) = viewModel.searchResutlsCells.first else {
            XCTFail("Directory should be in failed")
            return
        }
    }

    func testDirectoryViewModelValues() {
        let dataClient = MockAppDataClient()
        let staffResults = StaffModel.staffDemoData
        dataClient.getSearchDirectoryResult = .success(staffResults)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "searchResutlsCells updated")
        viewModel.$searchResutlsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetSearchResults(searchQuery: "Ali")
        waitForExpectations(timeout: 1.0)

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

    func testHelpfulNumberModel() {
        let testSuccessfulJSON = NumberModel.deomJSON
        let formattedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(NumberModel(json: formattedJSON))
    }

    func testNormalHelpfulNumberCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(HelpfulNumbersModel.helpfulNumbersDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "helpfulNumbersCells updated")
        viewModel.$helpfulNumbersCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetHelpHelpfulNumbers()
        waitForExpectations(timeout: 1.0)

        guard case .normal(_) = viewModel.helpfulNumbersCells.first else {
            XCTFail("Helpful Numbers should have value")
            return
        }
    }

    func testEmptyHelpfulCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(HelpfulNumbersModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        // Empty network response doesn't update helpfulNumbersCells; wait for loading to finish instead
        let exp = expectation(description: "load completes")
        viewModel.$showLoadingIndicator.dropFirst().filter { !$0 }.sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetHelpHelpfulNumbers()
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(viewModel.helpfulNumbersCells.isEmpty, "Helpful Numbers Cell should be empty")
    }

    func testErrorHelpfulNumberCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "helpfulNumbersCells updated")
        viewModel.$helpfulNumbersCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetHelpHelpfulNumbers()
        waitForExpectations(timeout: 1.0)

        guard case .error(_) = viewModel.helpfulNumbersCells.first else {
            XCTFail("Helpful Numbers should be in failed")
            return
        }
    }

    func testHelpfulNumberViewModelValues() {
        let dataClient = MockAppDataClient()
        let helpfulNumberResults = HelpfulNumbersModel.helpfulNumbersDemoData
        dataClient.getHelpfulNumbersResult = .success(helpfulNumberResults)
        let viewModel = DirectoryViewModel(dataClient: dataClient)

        let exp = expectation(description: "helpfulNumbersCells updated")
        viewModel.$helpfulNumbersCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetHelpHelpfulNumbers()
        waitForExpectations(timeout: 1.0)

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
