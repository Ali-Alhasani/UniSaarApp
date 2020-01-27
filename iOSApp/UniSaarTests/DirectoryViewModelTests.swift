//
//  DirectoryViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar
import SwiftyJSON
class DirectoryViewModelTests: XCTestCase {
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
    //test correctly formatted JSON
    func testDirectoryModel() {
        let testSuccessfulJSON = StaffModel.deomJSON
        XCTAssertNotNil(StaffModel(json: testSuccessfulJSON))
    }
    func testNormalDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(payload: StaffModel.staffDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetSearchResults(searchQuery: "Ali")
        guard case .some(.normal(_)) = viewModel.searchResutlsCells.value.first else {
            XCTFail("Directory should have value")
            return
        }
    }
    func testEmptyDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .success(payload: StaffModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetSearchResults(searchQuery: "")
        guard case .some(.empty) = viewModel.searchResutlsCells.value.first else {
            XCTFail("Directory Cell should be empty")
            return
        }
    }
    func testErrorDirectoryCells() {
        let dataClient = MockAppDataClient()
        dataClient.getSearchDirectoryResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetSearchResults(searchQuery: "")
        guard case .some(.error(_)) = viewModel.searchResutlsCells.value.first else {
            XCTFail("Directory should be in faild")
            return
        }
    }
    func testDirectoryViewModelValues() {
        let dataClient = MockAppDataClient()
        let staffResutls = StaffModel.staffDemoData
        dataClient.getSearchDirectoryResult = .success(payload: staffResutls)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetSearchResults(searchQuery: "Ali")
        switch viewModel.searchResutlsCells.value.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(staffResutls.staffResults.first?.fullName, cellViewModel.nameText)
            XCTAssertEqual(staffResutls.staffResults.first?.title, cellViewModel.titleText)
            XCTAssertEqual(staffResutls.staffResults.first?.staffID, cellViewModel.staffId)
        case .some(.error(let message)):
            XCTAssertNotNil(message)
        case .some(.empty):
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }

    func testHelpfulNumberModel() {
        let testSuccessfulJSON = NumberModel.deomJSON
        let foramtedJSON = JSON(testSuccessfulJSON)
        XCTAssertNotNil(NumberModel(json: foramtedJSON))
    }
    func testNormalHelpfulNumberCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(payload: HelpfulNumbersModel.helpfulNumbersDemoData)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetHelpHelpfulNumbers()
        guard case .some(.normal(_)) = viewModel.helpfulNumbersCells.value.first else {
            XCTFail("Helpful Numbers should have value")
            return
        }
    }
    func testEmptyHelpfulCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .success(payload: HelpfulNumbersModel(json: [:]))
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetHelpHelpfulNumbers()
        guard viewModel.helpfulNumbersCells.value.count == 0 else {
            XCTFail("Helpful Numbers Cell should be empty")
            return
        }
    }
    func testErrorHelpfulNumberCells() {
        let dataClient = MockAppDataClient()
        dataClient.getHelpfulNumbersResult = .failure(MyError.customError)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetHelpHelpfulNumbers()
        guard case .some(.error(_)) = viewModel.helpfulNumbersCells.value.first else {
            XCTFail("Helpful Numbers should be in faild")
            return
        }
    }
    func testHelpfulNumberViewModelValues() {

        let dataClient = MockAppDataClient()
        let helpfulNumberResutls = HelpfulNumbersModel.helpfulNumbersDemoData
        dataClient.getHelpfulNumbersResult = .success(payload: helpfulNumberResutls)
        let viewModel = DirectoryViewModel(dataClient: dataClient)
        viewModel.loadGetHelpHelpfulNumbers()
        switch viewModel.helpfulNumbersCells.value.first {
        case .normal(let cellViewModel):
            let numberItem = helpfulNumberResutls.numbers.first
            var itemForamted = (numberItem!.name ?? "") + "\n" + (numberItem!.number ?? "") + "\n"
            itemForamted += (numberItem!.link ?? "") +
                "\n" + (numberItem!.mail ?? "")

            XCTAssertEqual(itemForamted, cellViewModel.fortmatedText)
        case .some(.error(let message)):
            XCTAssertNotNil(message)
        case .some(.empty):
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
