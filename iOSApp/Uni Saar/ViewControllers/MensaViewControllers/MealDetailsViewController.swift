//
//  MealDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class MealDetailsViewController: UIViewController {
    @IBOutlet var mealDispalyNameLabel: UILabel!
    @IBOutlet var counterEntranceLabel: UILabel!
    @IBOutlet var generalNoticesLabel: UILabel!
    @IBOutlet var componentsLabel: UILabel!
    @IBOutlet var priceTagNamesLabel: UILabel!
    @IBOutlet var pricesLabel: UILabel!
    @IBOutlet var colorView: UIView!
    var mealItemViewModel: MensaMealCellViewModel?
    var meal = MealDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mealItemViewModel?.counterDisplayName
        colorView.setAsCircle(cornerRadius: colorView.frame.height / 2)
        colorView.backgroundColor = mealItemViewModel?.counterColor

        setupInitialState()
    }

    /// NATIVE iOS 26 API: The framework automatically tracks any @Observable referenced inside here.
    /// It automatically invalidates and refreshes the view when properties change.
    override func updateProperties() {
        updateUI()
    }

    private func setupInitialState() {
        // Equivalent to old bindViewModel loader logic
        if mealItemViewModel != nil {
            showLoadingActivity()
        }

        if let mealID = mealItemViewModel?.mensaMealsModel.mealID {
            meal.noticesText = mealItemViewModel?.noticesList
            // Clean Swift 6: Asynchronous loader called directly inside isolated Task context
            Task {
                await meal.loadGetMealDetails(mealId: mealID)
            }
        }
    }

    private func updateUI() {
        // Automatically handles showLoadingIndicator changes
        if meal.showLoadingIndicator { showLoadingActivity() } else { hideLoadingActivity() }

        // Defer the mutation to break out of the synchronous update cycle — avoids exclusivity crash
        if let alert = meal.currentAlert {
            Task { @MainActor [weak self] in
                guard let self else { return }
                meal.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }

        guard meal.mealDetails.mealDetailsModel != nil else { return }

        mealDispalyNameLabel.text = meal.mealDetails.mealName
        counterEntranceLabel.text = meal.mealDetails.mealCounterDescription
        generalNoticesLabel.attributedText = meal.mealDetails.generalNoticesText
        componentsLabel.attributedText = meal.mealDetails.mealComponetsText
        priceTagNamesLabel.text = meal.mealDetails.priceTagNamesText
        pricesLabel.text = meal.mealDetails.priceValuesText

        requestReview()
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }
}

extension MealDetailsViewController: SingleButtonDialogPresenter {}
