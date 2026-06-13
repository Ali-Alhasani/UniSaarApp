//
//  UpdatePropertiesLifecycleTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 5/31/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import XCTest

/// Verifies the native iOS 26 updateProperties() / updateUI() rendering pipeline.
///
/// Pattern for each test:
///   1. Load the VC from its storyboard.
///   2. Replace the lazy ViewModel with one backed by MockAppDataClient.
///   3. Await the data load so the ViewModel is fully populated.
///   4. Call setNeedsUpdateProperties() + view.layoutIfNeeded() to force one
///      rendering cycle — this invokes updateUI() which calls reloadData().
///   5. Assert that the table/collection view state reflects the ViewModel.
@MainActor
final class UpdatePropertiesLifecycleTests: XCTestCase {
    // MARK: - NewsFeedViewController

    func testNewsFeedVCUpdatePropertiesCycleRunsWithoutCrash() throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupTableView()

        // Smoke test: calling the iOS 26 invalidation + layout pass should not crash
        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()
        XCTAssertNotNil(viewController.newsTable, "newsTable must be wired — updateUI() depends on it")
    }

    func testNewsFeedVCTableRowCountMatchesViewModelAfterLoad() async throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        viewController.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewController.newsViewModel.loadGetNews(filterCatgroies: [])

        // Force the updateProperties() cycle → updateUI() → reloadData()
        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        XCTAssertEqual(
            viewController.newsTable.numberOfRows(inSection: 0),
            viewController.newsViewModel.newsCells.count,
            "Table row count must match ViewModel cell count after the updateProperties cycle"
        )
    }

    func testNewsFeedVCShowsEmptyCellWhenViewModelIsEmpty() async throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel(json: [:]))
        viewController.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewController.newsViewModel.loadGetNews(filterCatgroies: [])

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        // Empty response → exactly one .empty cell
        guard case .empty = viewController.newsViewModel.newsCells.first else {
            XCTFail("Expected an .empty cell when the network returns no items")
            return
        }
        XCTAssertEqual(viewController.newsTable.numberOfRows(inSection: 0), 1,
                       "Table should show exactly one row for the empty state")
    }

    func testNewsFeedVCShowsErrorCellOnNetworkFailure() async throws {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as? NewsFeedViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .failure(AppError.networkFailure)
        viewController.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await viewController.newsViewModel.loadGetNews(filterCatgroies: [])

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        guard case .error = viewController.newsViewModel.newsCells.first else {
            XCTFail("Expected an .error cell when the network request fails")
            return
        }
    }

    // MARK: - MensaViewController

    func testMensaVCCollectionItemCountMatchesViewModelAfterLoad() async throws {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as? MensaViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        viewController.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewController.mensaMenuViewModel.loadGetMensaMenu()

        // Force the updateProperties() cycle → updateUI() → reloadData()
        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        XCTAssertEqual(
            viewController.mensaCollectionView.numberOfItems(inSection: 0),
            viewController.mensaMenuViewModel.daysMenus.count,
            "Collection item count must match ViewModel day count after the updateProperties cycle"
        )
    }

    func testMensaVCPageControlMatchesDayCountAfterLoad() async throws {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as? MensaViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        viewController.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewController.mensaMenuViewModel.loadGetMensaMenu()

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        // pageControl.numberOfPages is set inside updateUI() — this verifies the lifecycle wiring
        XCTAssertEqual(
            viewController.pageControl.numberOfPages,
            viewController.mensaMenuViewModel.daysMenus.count,
            "pageControl.numberOfPages must match ViewModel day count — set in updateUI()"
        )
    }

    func testMensaVCShowsEmptyStateWhenViewModelIsEmpty() async throws {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as? MensaViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.emptyMenuDemoData)
        viewController.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await viewController.mensaMenuViewModel.loadGetMensaMenu()

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        guard case .empty = viewController.mensaMenuViewModel.daysMenus.first else {
            XCTFail("Expected an .empty cell when the mensa menu returns no days")
            return
        }
        XCTAssertEqual(viewController.mensaCollectionView.numberOfItems(inSection: 0), 1,
                       "Collection view should show exactly one item for the empty state")
    }

    // MARK: - MealDetailsViewController

    func testMealDetailsVCLabelsPopulatedViaUpdateProperties() async throws {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "MealDetailsViewControllerTest") as? MealDetailsViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()

        let dataClient = MockAppDataClient()
        let model = MealDetailsModel.mealDemoData
        dataClient.getMealResult = .success(model)
        // Replace the default ViewModel with one backed by mock data
        viewController.meal = MealDetailsViewModel(dataClient: dataClient)
        await viewController.meal.loadGetMealDetails(mealId: 1)

        // Force the updateProperties() cycle → updateUI() → label assignments
        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        XCTAssertEqual(viewController.mealDispalyNameLabel.text, model.mealName,
                       "mealDispalyNameLabel should be set to the meal name by updateUI()")
        XCTAssertEqual(viewController.priceTagNamesLabel.text,
                       model.prices.map { $0.priceTagName + "\n" }.joined(),
                       "priceTagNamesLabel should reflect all price tag names from the model")
    }

    func testMealDetailsVCShowsEmptyStateWhenLoadFails() async throws {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "MealDetailsViewControllerTest") as? MealDetailsViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .failure(AppError.networkFailure)
        viewController.meal = MealDetailsViewModel(dataClient: dataClient)
        await viewController.meal.loadGetMealDetails(mealId: 1)

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        // updateUI() defers the mutation via Task — currentAlert is still set when layoutIfNeeded() returns
        XCTAssertNil(viewController.meal.mealDetails.mealDetailsModel,
                     "mealDetailsModel should be nil after a failed load")
        XCTAssertNotNil(viewController.meal.currentAlert,
                        "An alert should be queued when the network request fails")
    }

    // MARK: - StaffDetailsViewController

    func testStaffDetailsVCLabelsPopulatedViaUpdateProperties() async throws {
        let storyboard = UIStoryboard(name: "DirectoryStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "StaffDetailsViewControllerTest") as? StaffDetailsViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .success(StaffDetailsModel(json: [
            "firstname": "Ali", "lastname": "Al-Hasani", "title": "Dr.", "mail": "ali@uni-saar.de"
        ]))
        // Replace the default ViewModel with one backed by mock data
        viewController.staff = StaffDetailsViewModel(dataClient: dataClient)
        await viewController.staff.loadGetStaffDetails(staffId: 1)

        // Force the updateProperties() cycle → updateUI() → label assignments
        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        XCTAssertEqual(viewController.nameLabel.text, "Ali Al-Hasani",
                       "nameLabel should be populated with the staff full name by updateUI()")
        XCTAssertEqual(viewController.staffTitleLabel.text, "Dr.",
                       "staffTitleLabel should reflect the title from the model")
    }

    func testStaffDetailsVCShowsAlertOnNetworkFailure() async throws {
        let storyboard = UIStoryboard(name: "DirectoryStoryboard", bundle: nil)
        let viewController = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "StaffDetailsViewControllerTest") as? StaffDetailsViewController
        )
        viewController.loadView()
        viewController.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .failure(AppError.networkFailure)
        viewController.staff = StaffDetailsViewModel(dataClient: dataClient)
        await viewController.staff.loadGetStaffDetails(staffId: 1)

        viewController.setNeedsUpdateProperties()
        viewController.view.layoutIfNeeded()

        XCTAssertNil(viewController.staff.staffDetails.staffDetailsModel,
                     "staffDetailsModel should be nil after a failed network request")
        XCTAssertNotNil(viewController.staff.currentAlert,
                        "An alert should be queued so updateUI() can present it")
    }
}
