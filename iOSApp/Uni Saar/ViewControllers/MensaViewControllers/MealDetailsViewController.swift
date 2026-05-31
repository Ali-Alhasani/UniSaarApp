//
//  MealDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Observation

@MainActor
class MealDetailsViewController: UIViewController {
    @IBOutlet weak var mealDispalyNameLabel: UILabel!
    @IBOutlet weak var counterEntranceLabel: UILabel!
    @IBOutlet weak var generalNoticesLabel: UILabel!
    @IBOutlet weak var componentsLabel: UILabel!
    @IBOutlet var priceTagNamesLabel: UILabel!
    @IBOutlet var pricesLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    var mealItemViewModel: MensaMealCellViewModel?
    var meal = MealDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = mealItemViewModel?.counterDisplayName
        colorView.setAsCircle(cornerRadius: colorView.frame.height/2)
        colorView.backgroundColor = mealItemViewModel?.counterColor
        if let mealID = mealItemViewModel?.mensaMealsModel.mealID {
            meal.noticesText = mealItemViewModel?.noticesList
            showLoadingActivity()
            Task { [weak self] in await self?.meal.loadGetMealDetails(mealId: mealID) }
        }
        startObserving()
    }

    private func startObserving() {
        withObservationTracking {
            let m = meal.mealDetails
            _ = meal.currentAlert
            meal.showLoadingIndicator ? showLoadingActivity() : hideLoadingActivity()
            if m.mealDetailsModel != nil {
                mealDispalyNameLabel.text = m.mealName
                counterEntranceLabel.text = m.mealCounterDescription
                generalNoticesLabel.attributedText = m.generalNoticesText
                componentsLabel.attributedText = m.mealComponetsText
                priceTagNamesLabel.text = m.priceTagNamesText
                pricesLabel.text = m.priceValuesText
                requestReview()
            }
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let alert = meal.currentAlert {
                    meal.currentAlert = nil
                    presentSingleButtonDialog(alert: alert)
                }
                startObserving()
            }
        }
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }
}

extension MealDetailsViewController: SingleButtonDialogPresenter { }
