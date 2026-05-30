//
//  MealDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Combine

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
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = mealItemViewModel?.counterDisplayName
        bindViewModel()
        colorView.setAsCircle(cornerRadius: colorView.frame.height/2)
        colorView.backgroundColor = mealItemViewModel?.counterColor
    }

    func bindViewModel() {
        if mealItemViewModel != nil {
            self.showLoadingActivity()
        }
        meal.$mealDetails
            .dropFirst()
            .sink { [weak self] meal in
                guard let self else { return }
                mealDispalyNameLabel.text = meal.mealName
                counterEntranceLabel.text = meal.mealCounterDescription
                generalNoticesLabel.attributedText = meal.generalNoticesText
                componentsLabel.attributedText = meal.mealComponetsText
                priceTagNamesLabel.text = meal.priceTagNamesText
                pricesLabel.text = meal.priceValuesText
                requestReview()
            }
            .store(in: &cancellables)

        meal.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.presentSingleButtonDialog(alert: alert)
            }
            .store(in: &cancellables)

        if let mealID = mealItemViewModel?.mensaMealsModel.mealID {
            meal.noticesText = mealItemViewModel?.noticesList
            meal.loadGetMealDetails(mealId: mealID)
        }

        meal.$showLoadingIndicator
            .dropFirst()
            .sink { [weak self] visible in
                guard let self else { return }
                visible ? showLoadingActivity() : hideLoadingActivity()
            }
            .store(in: &cancellables)
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }
}

extension MealDetailsViewController: SingleButtonDialogPresenter { }
