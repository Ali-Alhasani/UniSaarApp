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

    func testOnFilterListUpdatedFiredOnSuccess() async {
        var fired = false
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .success(MensaFilterModel())
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        viewModel.onFilterListUpdated = { fired = true }
        await viewModel.loadGetFilterList()
        XCTAssertTrue(fired)
    }

    func testOnFilterListUpdatedNotFiredOnError() async {
        var fired = false
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .failure(AppError.networkFailure)
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        viewModel.onFilterListUpdated = { fired = true }
        await viewModel.loadGetFilterList()
        XCTAssertFalse(fired)
    }

    func testOnAlertFiredOnError() async {
        var capturedAlert: SingleButtonAlert?
        let dataClient = MockAppDataClient()
        dataClient.getMensaFilterResult = .failure(AppError.networkFailure)
        let viewModel = FilterMensaViewModel(dataClient: dataClient)
        viewModel.onAlert = { capturedAlert = $0 }
        await viewModel.loadGetFilterList()
        XCTAssertNotNil(capturedAlert)
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
