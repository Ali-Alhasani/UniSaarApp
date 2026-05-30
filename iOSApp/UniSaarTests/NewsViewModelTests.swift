//
//  NewsViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/8/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
import Combine
@testable import Uni_Saar

@MainActor
class NewsViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testNewsModel() {
        let testSuccessfulJSON = NewsModel.deomJSON
        XCTAssertNotNil(NewsModel(json: testSuccessfulJSON))
    }

    func testNormalNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)

        let exp = expectation(description: "newsCells updated")
        viewModel.$newsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetNews(filterCatgroies: [])
        waitForExpectations(timeout: 1.0)

        guard case .normal(_) = viewModel.newsCells.first else {
            XCTFail("News should have value")
            return
        }
    }

    func testEmptyNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel(json: [:]))
        let viewModel = NewsFeedViewModel(dataClient: dataClient)

        let exp = expectation(description: "newsCells updated")
        viewModel.$newsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetNews(filterCatgroies: [])
        waitForExpectations(timeout: 1.0)

        guard case .empty = viewModel.newsCells.first else {
            XCTFail("News Cell should be empty")
            return
        }
    }

    func testErrorNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .failure(MyError.customError)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)

        let exp = expectation(description: "newsCells updated")
        viewModel.$newsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetNews(filterCatgroies: [])
        waitForExpectations(timeout: 1.0)

        guard case .error(_) = viewModel.newsCells.first else {
            XCTFail("News should be in failed")
            return
        }
    }

    func testNewsViewModelValues() {
        let dataClient = MockAppDataClient()
        let news = NewsFeedModel.newsDemoData
        dataClient.getNewsResult = .success(news)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)

        let exp = expectation(description: "newsCells updated")
        viewModel.$newsCells.dropFirst().sink { _ in exp.fulfill() }.store(in: &cancellables)

        viewModel.loadGetNews(filterCatgroies: [])
        waitForExpectations(timeout: 1.0)

        switch viewModel.newsCells.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(news.newsList.first?.title, cellViewModel.titleText)
            XCTAssertEqual(news.newsList.first?.subTitle, cellViewModel.subTitleText)
            XCTAssertEqual(news.newsList.first?.annoucementDate, cellViewModel.newsDate)
        case .error(let message):
            XCTAssertNotNil(message)
        case .empty:
            break
        case .none:
            XCTFail("View Model should not be empty!")
        }
    }
}
