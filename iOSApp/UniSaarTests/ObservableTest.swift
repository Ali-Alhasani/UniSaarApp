//
//  ObservableTest.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class ObservationTests: XCTestCase {
    /// showError is synchronous — no async needed
    func testOnAlertFiredOnError() {
        var capturedAlert: SingleButtonAlert?
        let viewModel = NewsFeedViewModel()
        viewModel.onAlert = { capturedAlert = $0 }
        viewModel.showError(error: AppError.networkFailure)
        XCTAssertNotNil(capturedAlert)
        XCTAssertNotNil(capturedAlert?.message)
    }

    func testOnAlertFiredOnServerError() {
        var capturedAlert: SingleButtonAlert?
        let viewModel = NewsFeedViewModel()
        viewModel.onAlert = { capturedAlert = $0 }
        viewModel.showError(error: AppError.serverMessage("test error"))
        XCTAssertNotNil(capturedAlert)
        XCTAssertNotNil(capturedAlert?.message)
    }

    /// Verifies that MockAppDataClient is properly injected and drives ViewModel state
    func testMockInjectionDeliversData() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        XCTAssertTrue(viewModel.newsCells.isEmpty)
        await viewModel.loadFirstPage(filterCatgroies: [])
        XCTAssertFalse(viewModel.newsCells.isEmpty)
        guard case let .normal(cell) = viewModel.newsCells.first else {
            XCTFail("Expected normal cell from mock")
            return
        }
        XCTAssertEqual(NewsFeedModel.newsDemoData.newsList.first?.title, cell.titleText)
    }

    func testLoadingClearsAfterLoad() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadFirstPage(filterCatgroies: [])
        XCTAssertFalse(viewModel.showLoadingIndicator, "showLoadingIndicator should clear once the load completes")
    }
}
