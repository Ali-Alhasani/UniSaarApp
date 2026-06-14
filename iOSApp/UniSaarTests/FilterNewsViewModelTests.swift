//
//  FilterNewsViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/20/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class FilterNewsViewModelTests: XCTestCase {
    func testOnFilterListUpdatedFiredOnSuccess() async {
        var fired = false
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .success([
            NewsCategories(categoryID: 1, categoryName: "News"),
            NewsCategories(categoryID: 2, categoryName: "Events")
        ])
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        viewModel.onFilterListUpdated = { fired = true }
        await viewModel.loadGetFilterList()
        XCTAssertTrue(fired)
    }

    func testOnFilterListUpdatedNotFiredOnError() async {
        var fired = false
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .failure(AppError.networkFailure)
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        viewModel.onFilterListUpdated = { fired = true }
        await viewModel.loadGetFilterList()
        XCTAssertFalse(fired)
    }

    func testOnAlertFiredOnError() async {
        var capturedAlert: SingleButtonAlert?
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .failure(AppError.networkFailure)
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        viewModel.onAlert = { capturedAlert = $0 }
        await viewModel.loadGetFilterList()
        XCTAssertNotNil(capturedAlert)
    }
}
