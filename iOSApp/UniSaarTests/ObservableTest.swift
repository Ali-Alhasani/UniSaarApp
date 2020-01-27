//
//  ObservableTest.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 1/27/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class ObservableTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testBindObservable() {
        let bindable = Bindable(false)

        let expectListenerCalled = expectation(description: "Observable is called")
        bindable.bind { value in
            XCTAssert(value == true, "testBind failed")
            expectListenerCalled.fulfill()
        }

        bindable.value = true
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testBindAndFire() {
        let bindable = Bindable(true)

        let expectListenerCalled = expectation(description: "Observable is called")
        bindable.bindAndFire { value in
            XCTAssert(value == true, "testBindAndFire failed")
            expectListenerCalled.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

}
