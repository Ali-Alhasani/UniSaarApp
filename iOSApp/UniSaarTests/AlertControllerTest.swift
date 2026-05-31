//
//  AlertControllerTest.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class AlertControllerTest: XCTestCase {

    func testAlert() {
        var handlerCalled = false

        let alert = SingleButtonAlert(
            message: "",
            action: AlertAction(handler: {
                handlerCalled = true
            }, tryAgainHandler: nil)
        )

        alert.action.handler!()

        XCTAssertTrue(handlerCalled, "Alert action handler should be called")
    }
}
