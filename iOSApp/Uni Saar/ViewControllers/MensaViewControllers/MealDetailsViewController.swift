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
        colorView.backgroundColor = mealItemViewModel.map { AppStyle.mensaCounterColor($0.colorModel) }
        setupViewModel()
        setupInitialState()
    }

    private func setupViewModel() {
        meal.onAlert = { [weak self] alert in self?.presentSingleButtonDialog(alert: alert) }
    }

    /// NATIVE iOS 26 API: The framework automatically tracks any @Observable referenced inside here.
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
            Task { [weak self] in
                await self?.meal.loadGetMealDetails(mealId: mealID)
            }
        }
    }

    private func updateUI() {
        // Automatically handles showLoadingIndicator changes
        if meal.showLoadingIndicator { showLoadingActivity() } else { hideLoadingActivity() }

        // Defer the mutation to break out of the synchronous update cycle — avoids exclusivity crash
        guard meal.mealDetails.mealDetailsModel != nil else { return }

        mealDispalyNameLabel.text = meal.mealDetails.mealName
        counterEntranceLabel.text = meal.mealDetails.mealCounterDescription
        generalNoticesLabel.setAttributedText(makeGeneralNoticesText(from: meal.mealDetails.generalNoticeItems))
        componentsLabel.setAttributedText(makeMealComponentsText(from: meal.mealDetails.mealComponentItems))
        priceTagNamesLabel.text = meal.mealDetails.priceTagNamesText
        pricesLabel.text = meal.mealDetails.priceValuesText

        requestReview()
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }
}

extension MealDetailsViewController: SingleButtonDialogPresenter {}

private extension MealDetailsViewController {
    func makeGeneralNoticesText(from items: [NoticeItem]) -> AttributedString {
        guard !items.isEmpty else { return AttributedString() }
        let newline = AttributedString(AppStyle.newLine, attributes: AppStyle.regularContainer)
        return items.reduce(into: AttributedString()) { result, item in
            if !result.characters.isEmpty { result += newline }
            let bullet = item.isWarning ? AppStyle.triangle : AppStyle.square
            result += AttributedString(bullet + item.text,
                                       attributes: item.isWarning ? AppStyle.warningContainer : AppStyle.regularContainer)
        }
    }

    func makeMealComponentsText(from items: [MealComponentItem]) -> AttributedString {
        guard !items.isEmpty else { return AttributedString() }
        let newline = AttributedString(AppStyle.newLine, attributes: AppStyle.regularContainer)
        return items.reduce(into: AttributedString()) { result, item in
            if !result.characters.isEmpty { result += newline }
            result += AttributedString(AppStyle.square + item.name, attributes: AppStyle.regularContainer)
            for notice in item.notices {
                let bullet = notice.isWarning ? AppStyle.newLineTabFLAG : AppStyle.BULLET
                result += AttributedString(bullet + notice.text,
                                           attributes: notice.isWarning ? AppStyle.warningContainer : AppStyle.regularContainer)
            }
        }
    }
}
