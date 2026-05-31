//
//  UpdatePropertiesLifecycleTests.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 5/31/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

import XCTest
@testable import Uni_Saar

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

    func testNewsFeedVCUpdatePropertiesCycleRunsWithoutCrash() {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as! NewsFeedViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupTableView()

        // Smoke test: calling the iOS 26 invalidation + layout pass should not crash
        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()
        XCTAssertNotNil(vc.newsTable, "newsTable must be wired — updateUI() depends on it")
    }

    func testNewsFeedVCTableRowCountMatchesViewModelAfterLoad() async {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as! NewsFeedViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel.newsDemoData)
        vc.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await vc.newsViewModel.loadGetNews(filterCatgroies: [])

        // Force the updateProperties() cycle → updateUI() → reloadData()
        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.newsTable.numberOfRows(inSection: 0),
            vc.newsViewModel.newsCells.count,
            "Table row count must match ViewModel cell count after the updateProperties cycle"
        )
    }

    func testNewsFeedVCShowsEmptyCellWhenViewModelIsEmpty() async {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as! NewsFeedViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .success(NewsFeedModel(json: [:]))
        vc.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await vc.newsViewModel.loadGetNews(filterCatgroies: [])

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        // Empty response → exactly one .empty cell
        guard case .empty = vc.newsViewModel.newsCells.first else {
            XCTFail("Expected an .empty cell when the network returns no items")
            return
        }
        XCTAssertEqual(vc.newsTable.numberOfRows(inSection: 0), 1,
                       "Table should show exactly one row for the empty state")
    }

    func testNewsFeedVCShowsErrorCellOnNetworkFailure() async {
        let storyboard = UIStoryboard(name: "NewsStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewsFeedViewControllerTest") as! NewsFeedViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupTableView()

        let dataClient = MockAppDataClient()
        dataClient.getNewsResult = .failure(MyError.customError)
        vc.newsViewModel = NewsFeedViewModel(dataClient: dataClient)
        await vc.newsViewModel.loadGetNews(filterCatgroies: [])

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        guard case .error(_) = vc.newsViewModel.newsCells.first else {
            XCTFail("Expected an .error cell when the network request fails")
            return
        }
    }

    // MARK: - MensaViewController

    func testMensaVCCollectionItemCountMatchesViewModelAfterLoad() async {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as! MensaViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        vc.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await vc.mensaMenuViewModel.loadGetMensaMenu()

        // Force the updateProperties() cycle → updateUI() → reloadData()
        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.mensaCollectionView.numberOfItems(inSection: 0),
            vc.mensaMenuViewModel.daysMenus.count,
            "Collection item count must match ViewModel day count after the updateProperties cycle"
        )
    }

    func testMensaVCPageControlMatchesDayCountAfterLoad() async {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as! MensaViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.menuDemoData)
        vc.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await vc.mensaMenuViewModel.loadGetMensaMenu()

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        // pageControl.numberOfPages is set inside updateUI() — this verifies the lifecycle wiring
        XCTAssertEqual(
            vc.pageControl.numberOfPages,
            vc.mensaMenuViewModel.daysMenus.count,
            "pageControl.numberOfPages must match ViewModel day count — set in updateUI()"
        )
    }

    func testMensaVCShowsEmptyStateWhenViewModelIsEmpty() async {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MensaViewControllerTest") as! MensaViewController
        vc.loadView()
        vc.viewDidLoad()
        vc.setupCollectionView()

        let dataClient = MockAppDataClient()
        dataClient.getMensaResult = .success(MensaMenuModel.emptyMenuDemoData)
        vc.mensaMenuViewModel = MensaMenuViewModel(dataClient: dataClient)
        await vc.mensaMenuViewModel.loadGetMensaMenu()

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        guard case .empty = vc.mensaMenuViewModel.daysMenus.first else {
            XCTFail("Expected an .empty cell when the mensa menu returns no days")
            return
        }
        XCTAssertEqual(vc.mensaCollectionView.numberOfItems(inSection: 0), 1,
                       "Collection view should show exactly one item for the empty state")
    }

    // MARK: - MealDetailsViewController

    func testMealDetailsVCLabelsPopulatedViaUpdateProperties() async {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MealDetailsViewControllerTest") as! MealDetailsViewController
        vc.loadView()
        vc.viewDidLoad()

        let dataClient = MockAppDataClient()
        let model = MealDetailsModel.mealDemoData
        dataClient.getMealResult = .success(model)
        // Replace the default ViewModel with one backed by mock data
        vc.meal = MealDetailsViewModel(dataClient: dataClient)
        await vc.meal.loadGetMealDetails(mealId: 1)

        // Force the updateProperties() cycle → updateUI() → label assignments
        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        XCTAssertEqual(vc.mealDispalyNameLabel.text, model.mealName,
                       "mealDispalyNameLabel should be set to the meal name by updateUI()")
        XCTAssertEqual(vc.priceTagNamesLabel.text,
                       model.prices.map { $0.priceTagName + "\n" }.joined(),
                       "priceTagNamesLabel should reflect all price tag names from the model")
    }

    func testMealDetailsVCShowsEmptyStateWhenLoadFails() async {
        let storyboard = UIStoryboard(name: "MensaStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MealDetailsViewControllerTest") as! MealDetailsViewController
        vc.loadView()
        vc.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getMealResult = .failure(MyError.customError)
        vc.meal = MealDetailsViewModel(dataClient: dataClient)
        await vc.meal.loadGetMealDetails(mealId: 1)

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        // updateUI() defers the mutation via Task — currentAlert is still set when layoutIfNeeded() returns
        XCTAssertNil(vc.meal.mealDetails.mealDetailsModel,
                     "mealDetailsModel should be nil after a failed load")
        XCTAssertNotNil(vc.meal.currentAlert,
                        "An alert should be queued when the network request fails")
    }

    // MARK: - StaffDetailsViewController

    func testStaffDetailsVCLabelsPopulatedViaUpdateProperties() async {
        let storyboard = UIStoryboard(name: "DirectoryStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "StaffDetailsViewControllerTest") as! StaffDetailsViewController
        vc.loadView()
        vc.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .success(StaffDetailsModel(json: [
            "firstname": "Ali", "lastname": "Al-Hasani", "title": "Dr.", "mail": "ali@uni-saar.de"
        ]))
        // Replace the default ViewModel with one backed by mock data
        vc.staff = StaffDetailsViewModel(dataClient: dataClient)
        await vc.staff.loadGetStaffDetails(staffId: 1)

        // Force the updateProperties() cycle → updateUI() → label assignments
        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        XCTAssertEqual(vc.nameLabel.text, "Ali Al-Hasani",
                       "nameLabel should be populated with the staff full name by updateUI()")
        XCTAssertEqual(vc.staffTitleLabel.text, "Dr.",
                       "staffTitleLabel should reflect the title from the model")
    }

    func testStaffDetailsVCShowsAlertOnNetworkFailure() async {
        let storyboard = UIStoryboard(name: "DirectoryStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "StaffDetailsViewControllerTest") as! StaffDetailsViewController
        vc.loadView()
        vc.viewDidLoad()

        let dataClient = MockAppDataClient()
        dataClient.getStaffDetailsResult = .failure(MyError.customError)
        vc.staff = StaffDetailsViewModel(dataClient: dataClient)
        await vc.staff.loadGetStaffDetails(staffId: 1)

        vc.setNeedsUpdateProperties()
        vc.view.layoutIfNeeded()

        XCTAssertNil(vc.staff.staffDetails.staffDetailsModel,
                     "staffDetailsModel should be nil after a failed network request")
        XCTAssertNotNil(vc.staff.currentAlert,
                        "An alert should be queued so updateUI() can present it")
    }
}
