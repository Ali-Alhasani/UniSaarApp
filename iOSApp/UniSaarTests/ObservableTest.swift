//
//  ObservableTest.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

@MainActor
final class ObservationTests: XCTestCase {

    // showError is synchronous — no async needed
    func testCurrentAlertSetOnError() {
        let viewModel = NewsFeedViewModel()
        viewModel.showError(error: MyError.customError)
        XCTAssertNotNil(viewModel.currentAlert)
        XCTAssertNotNil(viewModel.currentAlert?.message)
    }

    func testCurrentAlertSetOnLLError() {
        let viewModel = NewsFeedViewModel()
        viewModel.showError(error: LLError(status: false, message: "test error"))
        XCTAssertNotNil(viewModel.currentAlert)
        XCTAssertNotNil(viewModel.currentAlert?.message)
    }

    // Verifies that MockAppDataClient is properly injected and drives ViewModel state
    func testMockInjectionDeliversData() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        XCTAssertTrue(viewModel.newsCells.isEmpty)
        await viewModel.loadGetNews(filterCatgroies: [])
        XCTAssertFalse(viewModel.newsCells.isEmpty)
        guard case .normal(let cell) = viewModel.newsCells.first else {
            XCTFail("Expected normal cell from mock")
            return
        }
        XCTAssertEqual(NewsFeedModel.newsDemoData.newsList.first?.title, cell.titleText)
    }
}
