//
//  StaffDetailsViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class StaffDetailsViewModelTests: XCTestCase {
    func testStaffDetailsLoaded() async {
        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .success(StaffDetailsModel(json: [
            "firstname": "Ali", "lastname": "Al-Hasani", "title": "Dr.", "mail": "ali@uni-saar.de"
        ]))
        let viewModel = StaffDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetStaffDetails(staffId: 1)
        XCTAssertNotNil(viewModel.staffDetails.staffDetailsModel)
    }

    func testStaffDetailsValues() async {
        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .success(StaffDetailsModel(json: [
            "firstname": "Ali", "lastname": "Al-Hasani", "title": "Dr.", "mail": "ali@uni-saar.de"
        ]))
        let viewModel = StaffDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetStaffDetails(staffId: 1)
        XCTAssertEqual(viewModel.staffDetails.fullName, "Ali Al-Hasani")
        XCTAssertEqual(viewModel.staffDetails.titleText, "Dr.")
    }

    func testStaffDetailsError() async {
        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .failure(AppError.networkFailure)
        let viewModel = StaffDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetStaffDetails(staffId: 1)
        XCTAssertNil(viewModel.staffDetails.staffDetailsModel)
        XCTAssertNotNil(viewModel.currentAlert)
    }
}
