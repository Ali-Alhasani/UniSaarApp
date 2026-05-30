//
//  PublisherTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
import Combine
@testable import Uni_Saar

@MainActor
class PublisherTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testCurrentAlertPublishesOnError() {
        let viewModel = NewsFeedViewModel()
        let exp = expectation(description: "currentAlert fires on Error")

        viewModel.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .sink { alert in
                XCTAssertNotNil(alert.message)
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.showError(error: MyError.customError)
        waitForExpectations(timeout: 1.0)
    }

    func testCurrentAlertPublishesOnLLError() {
        let viewModel = NewsFeedViewModel()
        let exp = expectation(description: "currentAlert fires on LLError")

        viewModel.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .sink { alert in
                XCTAssertNotNil(alert.message)
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.showError(error: LLError(status: false, message: "test error"))
        waitForExpectations(timeout: 1.0)
    }
}
