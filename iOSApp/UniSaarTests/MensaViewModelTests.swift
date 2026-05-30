//
//  MensaViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
import Combine
@testable import Uni_Saar

@MainActor
class MensaViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

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
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)

        let exp = expectation(description: "daysMenus updated")
        viewModel.$daysMenus.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMensaMenu()
        waitForExpectations(timeout: 1.0)

        guard case .normal(_) = viewModel.daysMenus.first else {
            XCTFail("mensa menu should have values")
            return
        }
    }

    func testEmptyMensaCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.emptyMenuDemoData)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)

        let exp = expectation(description: "daysMenus updated")
        viewModel.$daysMenus.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMensaMenu()
        waitForExpectations(timeout: 1.0)

        guard case .empty = viewModel.daysMenus.first else {
            XCTFail("mensa menu table view should be empty, no data returned")
            return
        }
    }

    func testErrorMensaCells() {
        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .failure(MyError.customError)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)

        let exp = expectation(description: "daysMenus updated")
        viewModel.$daysMenus.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMensaMenu()
        waitForExpectations(timeout: 1.0)

        guard case .error(_) = viewModel.daysMenus.first else {
            XCTFail("Mensa request should be failed and return error message")
            return
        }
    }

    func testMensaViewModelValues() {
        let dataClient = MockAppDataClient()
        let menu = MensaMenuModel.menuDemoData
        dataClient.getMensaResult = .success(menu)
        let viewModel = MensaMenuViewModel(dataClient: dataClient)

        let exp = expectation(description: "daysMenus updated")
        viewModel.$daysMenus.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMensaMenu()
        waitForExpectations(timeout: 1.0)

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

    func testNormalMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(MealDetailsModel.mealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)

        let exp = expectation(description: "mealDetails updated")
        viewModel.$mealDetails.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMealDetails(mealId: 1)
        waitForExpectations(timeout: 1.0)

        guard MealDetailsModel.mealDemoData === viewModel.mealDetails.mealDetailsModel else {
            XCTFail("mensa meal should have values")
            return
        }
    }

    func testEmptyMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .success(MealDetailsModel.emptyMealDemoData)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)

        let exp = expectation(description: "mealDetails updated")
        viewModel.$mealDetails.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMealDetails(mealId: 1)
        waitForExpectations(timeout: 1.0)

        if MealDetailsModel.emptyMealDemoData !== viewModel.mealDetails.mealDetailsModel {
            XCTFail("mensa menu table view should be empty, no data returned")
        }
    }

    func testErrorMealDetails() {
        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .failure(MyError.customError)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)

        // Error path sets showLoadingIndicator=false and currentAlert, but does not update mealDetails
        let exp = expectation(description: "load completes after error")
        viewModel.$showLoadingIndicator.dropFirst().filter { !$0 }.sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMealDetails(mealId: 1)
        waitForExpectations(timeout: 1.0)

        XCTAssertNil(viewModel.mealDetails.mealDetailsModel, "Mensa meal details request should be failed and return empty model")
    }

    func testMealDetailsValues() {
        let dataClient = MockAppDataClient()
        let model = MealDetailsModel.mealDemoData
        dataClient.getMealResult = .success(model)
        let viewModel = MealDetailsViewModel(dataClient: dataClient)

        let exp = expectation(description: "mealDetails updated")
        viewModel.$mealDetails.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetMealDetails(mealId: 1)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(viewModel.mealDetails.mealName, model.mealName)
        XCTAssertEqual(viewModel.mealDetails.mealCounterDescription, model.counterDescription)
        XCTAssertEqual(viewModel.mealDetails.priceTagNamesText, model.prices.map { $0.priceTagName + "\n" }.joined())
        XCTAssertEqual(viewModel.mealDetails.priceValuesText, model.prices.map { $0.price + " € \n" }.joined())
    }
}
