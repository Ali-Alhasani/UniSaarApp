//
//  FilterMensaViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class FilterMensaViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppSessionManager.shared.isFoodAlarmEnabled = false
        AppSessionManager.shared.foodAlarmTime = nil
    }

    override func tearDown() {
        AppSessionManager.shared.isFoodAlarmEnabled = false
        AppSessionManager.shared.foodAlarmTime = nil
        super.tearDown()
    }

    func testDidUpdateFilterListOnSuccess() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .success(MensaFilterModel(json: [:]))
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        await viewModel.loadGetFilterList()
        XCTAssertTrue(viewModel.didUpdatefilterList)
    }

    func testDidUpdateFilterListFalseOnError() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .failure(AppError.networkFailure)
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        await viewModel.loadGetFilterList()
        XCTAssertFalse(viewModel.didUpdatefilterList)
    }

    func testCurrentAlertOnError() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .failure(AppError.networkFailure)
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        await viewModel.loadGetFilterList()
        XCTAssertNotNil(viewModel.currentAlert)
    }

    func testSelectedAlarmTimePersistsToSession() {
        let viewModel = FilterMensaViewModel()
        let testTime = Date()
        viewModel.selectedAlramTime = testTime
        XCTAssertEqual(AppSessionManager.shared.foodAlarmTime, testTime)
    }

    func testFoodAlarmEnabledPersistsToSession() {
        let viewModel = FilterMensaViewModel()
        viewModel.isFoodAlarmEnabled = true
        XCTAssertTrue(AppSessionManager.shared.isFoodAlarmEnabled)
    }
}
