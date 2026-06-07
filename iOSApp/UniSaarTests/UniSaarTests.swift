//
//  UniSaarTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

class UniSaarTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    /// test mapping mensa menu color into apple dynamic colors
    func testMensaColor() {
        XCTAssertEqual(.systemRed, AppStyle.mensaCounterColor(MensaColor(red: 217, green: 38, blue: 26)))
        XCTAssertEqual(.systemBlue, AppStyle.mensaCounterColor(MensaColor(red: 21, green: 135, blue: 207)))
        XCTAssertEqual(.systemYellow, AppStyle.mensaCounterColor(MensaColor(red: 245, green: 204, blue: 43)))
        XCTAssertEqual(.systemGreen, AppStyle.mensaCounterColor(MensaColor(red: 16, green: 107, blue: 10)))
        XCTAssertEqual(.systemPurple, AppStyle.mensaCounterColor(MensaColor(red: 135, green: 10, blue: 194)))
        XCTAssertNotEqual(.systemRed, AppStyle.mensaCounterColor(MensaColor(red: 210, green: 38, blue: 26)))
        XCTAssertNotEqual(.systemBlue, AppStyle.mensaCounterColor(MensaColor(red: 21, green: 130, blue: 207)))
        XCTAssertNotEqual(.systemYellow, AppStyle.mensaCounterColor(MensaColor(red: 245, green: 204, blue: 40)))
        XCTAssertNotEqual(.systemGreen, AppStyle.mensaCounterColor(MensaColor(red: 160, green: 10, blue: 100)))
        XCTAssertNotEqual(.systemPurple, AppStyle.mensaCounterColor(MensaColor(red: 135, green: 10, blue: 195)))
        XCTAssertEqual(UIColor(red: 200 / 256, green: 38 / 256, blue: 26 / 256, alpha: 100), AppStyle.mensaCounterColor(MensaColor(red: 200, green: 38, blue: 26)))
    }
}
