//
//  ViewExtensionTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 5/30/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

// MARK: - UITableView loading indicator

@MainActor
class UITableViewLoadingTests: XCTestCase {
    var tableView: UITableView!

    override func setUp() {
        super.setUp()
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        tableView.refreshControl = UIRefreshControl()
    }

    func testShowingLoadingViewAddsSpinnerFooter() {
        tableView.showingLoadingView()
        XCTAssertTrue(tableView.tableFooterView is UIActivityIndicatorView, "tableFooterView should be a UIActivityIndicatorView while loading")
    }

    func testHideLoadingViewClearsFooter() {
        tableView.showingLoadingView()
        XCTAssertNotNil(tableView.tableFooterView)
        tableView.hideLoadingView()
        XCTAssertNil(tableView.tableFooterView, "tableFooterView should be nil after hideLoadingView")
    }
}

// MARK: - UICollectionView loading indicator

@MainActor
class UICollectionViewLoadingTests: XCTestCase {
    var collectionView: UICollectionView!

    override func setUp() {
        super.setUp()
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), collectionViewLayout: layout)
        collectionView.refreshControl = UIRefreshControl()
    }

    func testShowingLoadingViewSetsSpinnerBackground() {
        collectionView.showingLoadingView()
        XCTAssertTrue(collectionView.backgroundView is UIActivityIndicatorView, "backgroundView should be a UIActivityIndicatorView while loading")
    }

    func testHideLoadingViewClearsSpinnerBackground() {
        collectionView.showingLoadingView()
        XCTAssertNotNil(collectionView.backgroundView)
        collectionView.hideLoadingView()
        XCTAssertNil(collectionView.backgroundView, "backgroundView should be nil after hideLoadingView")
    }

    func testHideLoadingViewPreservesNonSpinnerBackground() {
        let placeholder = UIView()
        collectionView.backgroundView = placeholder
        collectionView.hideLoadingView()
        XCTAssertTrue(collectionView.backgroundView === placeholder, "hideLoadingView should not clear a non-spinner backgroundView")
    }
}

// MARK: - UITableViewCell empty state

@MainActor
class UITableViewCellEmptyStateTests: XCTestCase {
    func testSetupEmptyCellSetsText() {
        let cell = UITableViewCell()
        _ = cell.setupEmptyCell(message: "No results found")
        let config = cell.contentConfiguration as? UIListContentConfiguration
        XCTAssertEqual(config?.text, "No results found", "setupEmptyCell should set contentConfiguration text")
    }

    func testSetupEmptyCellDisablesInteraction() {
        let cell = UITableViewCell()
        _ = cell.setupEmptyCell(message: "Empty")
        XCTAssertFalse(cell.isUserInteractionEnabled, "setupEmptyCell should disable user interaction")
    }

    func testSetupEmptyCellTextWraps() {
        let cell = UITableViewCell()
        _ = cell.setupEmptyCell(message: "Test")
        let config = cell.contentConfiguration as? UIListContentConfiguration
        XCTAssertEqual(config?.textProperties.numberOfLines, 0, "setupEmptyCell should allow unlimited text lines")
    }
}

// MARK: - showLoadingIndicator

@MainActor
final class LoadingIndicatorTests: XCTestCase {
    func testLoadingStartsTrueAndClearsAfterLoad() async {
        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        let viewModel = NewsFeedViewModel(dataClient: dataClient)
        let task = Task { await viewModel.loadFirstPage(filterCatgroies: []) }
        await Task.yield() // let Task start and execute synchronous preamble
        XCTAssertTrue(viewModel.showLoadingIndicator, "showLoadingIndicator should be true while loading")
        await task.value
        XCTAssertFalse(viewModel.showLoadingIndicator, "showLoadingIndicator should be false after load completes")
    }
}
