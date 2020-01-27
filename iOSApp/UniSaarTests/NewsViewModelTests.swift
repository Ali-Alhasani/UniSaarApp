//
//  NewsViewModelTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 12/8/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

class NewsViewModelTests: XCTestCase {
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
    func testNewsModel() {
        let testSuccessfulJSON = NewsModel.deomJSON
         XCTAssertNotNil(NewsModel(json: testSuccessfulJSON))
    }
    func testNormalNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(payload: NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        viewModel.loadGetNews(filterCatgroies: [])
        guard case .some(.normal(_)) = viewModel.newsCells.value.first else {
            XCTFail("News should have value")
            return
        }
    }
    func testEmptyNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(payload: NewsFeedModel(json: [:]))
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        viewModel.loadGetNews(filterCatgroies: [])
        guard case .some(.empty) = viewModel.newsCells.value.first else {
            XCTFail("News Cell should be empty")
            return
        }
    }
    func testErrorNewsCells() {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .failure(MyError.customError)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        viewModel.loadGetNews(filterCatgroies: [])
        guard case .some(.error(_)) = viewModel.newsCells.value.first else {
            XCTFail("News should be in faild")
            return
        }
    }
    func testNewsViewModelValues() {
        let dataClient = MockAppDataClient()
        let news = NewsFeedModel.newsDemoData
        dataClient.getNewsResult = .success(payload: news)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        viewModel.loadGetNews(filterCatgroies: [])
        switch viewModel.newsCells.value.first {
        case .normal(let cellViewModel):
            XCTAssertEqual(news.newsList.first?.title, cellViewModel.titleText)
            XCTAssertEqual(news.newsList.first?.subTitle, cellViewModel.subTitleText)
            XCTAssertEqual(news.newsList.first?.annoucementDate, cellViewModel.newsDate)
        case .some(.error(let message)):
            XCTAssertNotNil(message)
        case .some(.empty):
            break
        case .none:
             XCTFail("View Model should not be empty!")
        }
    }
}
