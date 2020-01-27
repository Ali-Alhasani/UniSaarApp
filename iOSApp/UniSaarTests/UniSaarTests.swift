//
//  UniSaarTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

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
    //test mapping mensa menu color into apple dynamic colors
    func testMensaColor() {
        XCTAssertEqual(.systemRed, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 217, "g": 38, "b": 26])))
        XCTAssertEqual(.systemBlue, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 21, "g": 135, "b": 207])))
        XCTAssertEqual(.systemYellow, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 245, "g": 204, "b": 43])))
        XCTAssertEqual(.systemGreen, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 16, "g": 107, "b": 10])))
        XCTAssertEqual(.systemPurple, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 135, "g": 10, "b": 194])))
        XCTAssertNotEqual(.systemRed, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 210, "g": 38, "b": 26])))
        XCTAssertNotEqual(.systemBlue, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 21, "g": 130, "b": 207])))
        XCTAssertNotEqual(.systemYellow, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 245, "g": 204, "b": 40])))
        XCTAssertNotEqual(.systemGreen, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 160, "g": 10, "b": 100])))
        XCTAssertNotEqual(.systemPurple, AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 135, "g": 10, "b": 195])))
        XCTAssertEqual(UIColor(red: (200/256), green: (38/256), blue: (26/256), alpha: 100), AppStyle.mensaCounterColor(MensaColorModel(json: ["r": 200, "g": 38, "b": 26])))
    }
}
