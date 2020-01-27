//
//  MensaViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class MensaViewModelTests: XCTestCase {
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
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    //test correctly formatted JSON
    func testMensaModel() {
        let testSuccessfulJSON = MensaMenuModel.deomJSON
        XCTAssertNotNil(MensaMenuModel(json: testSuccessfulJSON))
    }

    func testMensaTodayModel() {
        let testSuccessfulJSON = MensaDayModel.menuDemoData
        XCTAssertNotNil(MensaDayModel(json: testSuccessfulJSON))
    }
    func testNormalMensaCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(payload: MensaMenuModel.menuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        viewModel.loadGetMensaMenu()
        guard case .some(.normal(_)) = viewModel.daysMenus.value.first else {
            XCTFail("mensa menu should has values")
            return
        }
    }
    func testEmptyMensaCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(payload: MensaMenuModel.emptyMenuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        viewModel.loadGetMensaMenu()
        guard case .some(.empty) = viewModel.daysMenus.value.first else {
            XCTFail("mensa menu table view should be empty, no data returned ")
            return
        }
    }
    func testErrorMensaCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .failure(MyError.customError)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        viewModel.loadGetMensaMenu()
        guard case .some(.error(_)) = viewModel.daysMenus.value.first else {
            XCTFail("Mensa request should be in faild, and return error message")
            return
        }
    }
    func testMensaViewModelValues() {
        let dataClient = MockAppDataClient()
        let menu = MensaMenuModel.menuDemoData
        dataClient.getMensaResult = .success(payload: menu)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        viewModel.loadGetMensaMenu()
        switch viewModel.daysMenus.value.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.mealDispalyName, cellViewModel.mealsCells.first?.mealName)
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.counterDisplayName, cellViewModel.mealsCells.first?.counterDisplayName)
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.openingHoursText, cellViewModel.mealsCells.first?.openingHoursText)
            if let countersMeal =  menu.daysMenus.first?.countersMeals, let color = countersMeal.first?.color {
                XCTAssertEqual(AppStyle.mensaCounterColor(color), cellViewModel.mealsCells.first?.counterColor)
            }
        case .some(.error(let message)):
            XCTAssertNotNil(message)
        case .some(.empty):
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }

    func testNormalMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(payload: MealDetailsModel.mealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        viewModel.loadGetMealDetails(mealId: 1)
        // they should be identical
        guard MealDetailsModel.mealDemoData === viewModel.mealDetails.value.mealDetailsModel else {
            XCTFail("mensa meal should has values")
            return
        }
    }
    func testEmptyMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(payload: MealDetailsModel.emptyMealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        viewModel.loadGetMealDetails(mealId: 1)
        // they should be identical
        if MealDetailsModel.emptyMealDemoData !== viewModel.mealDetails.value.mealDetailsModel {
            XCTFail("mensa menu table view should be empty, no data returned ")
            return
        }
    }
    func testErrorMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .failure(MyError.customError)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        viewModel.loadGetMealDetails(mealId: 1)
        guard viewModel.mealDetails.value.mealDetailsModel == nil else {
            XCTFail("Mensa meal details request should be in faild and empty, and return error message")
            return
        }
    }

    func testMealDetailsValues() {
        let dataClient = MockAppDataClient()
        let model = MealDetailsModel.mealDemoData
        dataClient.getMealResult = .success(payload: model)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        viewModel.loadGetMealDetails(mealId: 1)

        XCTAssertEqual(viewModel.mealDetails.value.mealName, model.mealName)
        XCTAssertEqual(viewModel.mealDetails.value.mealCounterDescription, model.counterDescription)
        XCTAssertEqual(viewModel.mealDetails.value.priceTagNamesText, model.prices.map {$0.priceTagName + "\n"}.joined())
        XCTAssertEqual(viewModel.mealDetails.value.priceValuesText, model.prices.map {$0.price + " € \n"}.joined())
    }
}
