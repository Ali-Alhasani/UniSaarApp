//
//  EventViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

@MainActor
final class EventViewModelTests: XCTestCase {
    func testSelectedDateEventsEmptyWhenNotCurrentMonth() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        XCTAssertTrue(viewModel.selectedDateEvents.isEmpty)
    }

    func testSelectedDateEventsEmptyOnError() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .failure(MyError.customError)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        XCTAssertTrue(viewModel.selectedDateEvents.isEmpty)
    }

    func testNormalEventCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        guard case .normal = viewModel.eventCells.first else {
            XCTFail("Event cells should have values")
            return
        }
    }

    func testEmptyEventCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .success(NewsFeedModel(json: [:]))
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        guard case .empty = viewModel.eventCells.first else {
            XCTFail("Event cells should be empty")
            return
        }
    }

    func testErrorEventCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .failure(AppError.networkFailure)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        guard case .error = viewModel.eventCells.first else {
            XCTFail("Event cells should have error")
            return
        }
    }

    func testGetDayEventsReturnsEmptyForNonMatchingDate() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        viewModel.getDayEvents(day: Date(timeIntervalSince1970: 0))
        XCTAssertTrue(viewModel.selectedDateEvents.isEmpty)
    }

    func testCountDayEventsReturnsZeroForNonMatchingDate() async {
        let dataClient = MockAppDataClient()
        dataClient.getEventsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = EventViewModel(dataClient: dataClient)
        await viewModel.loadGetEvents(month: "12", year: "2019")
        let count = viewModel.countDayEvents(day: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(count, 0)
    }
}
