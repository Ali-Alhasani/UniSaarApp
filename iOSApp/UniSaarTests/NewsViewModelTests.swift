//
//  NewsViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/8/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

@MainActor
final class NewsViewModelTests: XCTestCase {

    func testNewsModel() {
        let testSuccessfulJSON = NewsModel.deomJSON
        XCTAssertNotNil(NewsModel(json: testSuccessfulJSON))
    }

    func testNormalNewsCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadGetNews(filterCatgroies: [])
        guard case .normal = viewModel.newsCells.first else { XCTFail("Expected normal cell"); return }
    }

    func testEmptyNewsCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel(json: [:]))
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadGetNews(filterCatgroies: [])
        guard case .empty = viewModel.newsCells.first else { XCTFail("Expected empty cell"); return }
    }

    func testErrorNewsCells() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .failure(MyError.customError)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadGetNews(filterCatgroies: [])
        guard case .error = viewModel.newsCells.first else { XCTFail("Expected error cell"); return }
    }

    func testIsFreshLoadSetAfterLoad() async {
        let testSuccessfulJSON = NewsFeedModel.newsDemoData
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(testSuccessfulJSON)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadGetNews(filterCatgroies: [])
        XCTAssertTrue(viewModel.isFreshLoad)
    }

    func testNewsViewModelValues() async {
        let news = NewsFeedModel.newsDemoData
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(news)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewModel.loadGetNews(filterCatgroies: [])
        guard case .normal(let cell) = viewModel.newsCells.first else { XCTFail("Expected normal cell"); return }
        XCTAssertEqual(news.newsList.first?.title, cell.titleText)
        XCTAssertEqual(news.newsList.first?.subTitle, cell.subTitleText)
        XCTAssertEqual(news.newsList.first?.annoucementDate, cell.newsDate)
    }
}
