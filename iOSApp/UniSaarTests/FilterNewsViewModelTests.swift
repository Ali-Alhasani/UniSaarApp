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
    func testDidUpdateFilterListOnSuccess() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .success([
            NewsCategories(json: ["id": 1, "name": "News"]),
            NewsCategories(json: ["id": 2, "name": "Events"])
        ])
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        await viewModel.loadGetFilterList()
        XCTAssertTrue(viewModel.didUpdatefilterList)
    }

    func testDidUpdateFilterListFalseOnError() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .failure(MyError.customError)
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        await viewModel.loadGetFilterList()
        XCTAssertFalse(viewModel.didUpdatefilterList)
    }

    func testOnAlertFiredOnError() async {
        var capturedAlert: SingleButtonAlert?
        let dataClient = MockAppDataClient()
        dataClient.getNewsCategoriesResult = .failure(MyError.customError)
        let viewModel = FilterNewsViewModel(dataClient: dataClient)
        viewModel.onAlert = { capturedAlert = $0 }
        await viewModel.loadGetFilterList()
        XCTAssertNotNil(capturedAlert)
    }
}
