//
//  AlertControllerTest.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class AlertControllerTest: XCTestCase {
    func testAlert() {
        var retried = false

        let alert = SingleButtonAlert(
            message: "test error",
            action: AlertAction(tryAgainHandler: { retried = true })
        )

        alert.action.tryAgainHandler?()

        XCTAssertTrue(retried, "Try again handler should be called")
    }
}
