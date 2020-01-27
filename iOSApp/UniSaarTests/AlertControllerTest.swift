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
        let expectAlertActionHandlerCall = expectation(description: "Alert action handler called")

        let alert = SingleButtonAlert(
            message: "",
            action: AlertAction(handler: {
                expectAlertActionHandlerCall.fulfill()
            })
        )

        alert.action.handler!()

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
