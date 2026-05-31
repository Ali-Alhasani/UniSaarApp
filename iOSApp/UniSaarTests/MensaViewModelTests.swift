//
//  MensaViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

@MainActor
final class MensaViewModelTests: XCTestCase {

    func testMensaModel() {
        let testSuccessfulJSON = MensaMenuModel.deomJSON
        XCTAssertNotNil(MensaMenuModel(json: testSuccessfulJSON))
    }

    func testMensaTodayModel() {
        let testSuccessfulJSON = MensaDayModel.menuDemoData
        XCTAssertNotNil(MensaDayModel(json: testSuccessfulJSON))
    }

    func testNormalMensaCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewModel.loadGetMensaMenu()
        guard case .normal(_) = viewModel.daysMenus.first else {
            XCTFail("mensa menu should have values")
            return
        }
    }

    func testEmptyMensaCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.emptyMenuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewModel.loadGetMensaMenu()
        guard case .empty = viewModel.daysMenus.first else {
            XCTFail("mensa menu table view should be empty, no data returned")
            return
        }
    }

    func testErrorMensaCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .failure(MyError.customError)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewModel.loadGetMensaMenu()
        guard case .error(_) = viewModel.daysMenus.first else {
            XCTFail("Mensa request should be failed and return error message")
            return
        }
    }

    func testMensaViewModelValues() async {
        let dataClient = MockAppDataClient()
        let menu = MensaMenuModel.menuDemoData
        dataClient.getMensaResult = .success(menu)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewModel.loadGetMensaMenu()
        switch viewModel.daysMenus.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.mealDispalyName, cellViewModel.mealsCells.first?.mealName)
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.counterDisplayName, cellViewModel.mealsCells.first?.counterDisplayName)
            XCTAssertEqual(menu.daysMenus.first?.countersMeals.first?.openingHoursText, cellViewModel.mealsCells.first?.openingHoursText)
            if let countersMeal = menu.daysMenus.first?.countersMeals, let color = countersMeal.first?.color {
                XCTAssertEqual(AppStyle.mensaCounterColor(color), cellViewModel.mealsCells.first?.counterColor)
            }
        case .error(let message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }

    // MARK: - MealDetails

    func testNormalMealDetails() async {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(MealDetailsModel.mealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetMealDetails(mealId: 1)
        guard MealDetailsModel.mealDemoData === viewModel.mealDetails.mealDetailsModel else {
            XCTFail("mensa meal should have values")
            return
        }
    }

    func testEmptyMealDetails() async {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(MealDetailsModel.emptyMealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetMealDetails(mealId: 1)
        if MealDetailsModel.emptyMealDemoData !== viewModel.mealDetails.mealDetailsModel {
            XCTFail("mensa meal details should reflect the returned empty model")
        }
    }

    func testErrorMealDetails() async {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .failure(MyError.customError)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetMealDetails(mealId: 1)
        XCTAssertNil(viewModel.mealDetails.mealDetailsModel, "Mensa meal details request should be failed and return empty model")
    }

    func testMealDetailsValues() async {
        let dataClient = MockAppDataClient()
        let model = MealDetailsModel.mealDemoData
        dataClient.getMealResult = .success(model)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)
        await viewModel.loadGetMealDetails(mealId: 1)
        XCTAssertEqual(viewModel.mealDetails.mealName, model.mealName)
        XCTAssertEqual(viewModel.mealDetails.mealCounterDescription, model.counterDescription)
        XCTAssertEqual(viewModel.mealDetails.priceTagNamesText, model.prices.map { $0.priceTagName + "\n" }.joined())
        XCTAssertEqual(viewModel.mealDetails.priceValuesText, model.prices.map { $0.price + " € \n" }.joined())
    }
}
