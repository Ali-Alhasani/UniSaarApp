//
//  MealDetailsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
class MealDetailsViewModel: ParentViewModel {
    var mealDetails: Bindable = Bindable(MealViewModel())
    var noticesText: [FilterNoticesListCache]?
    // MARK: - Object Lifecycle
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    func loadGetMealDetails(mealId: Int) {
        showLoadingIndicator.value = true
        dataClient.getMealDetails(mealId: mealId, completion: { [weak self] result in
            switch result {
            case .success(let meal):
                self?.mealDetails.value = MealViewModel(meal, noticesText: self?.noticesText)
                  self?.showLoadingIndicator.value = false
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.showError(error: error)
            }
        })
    }
    func loadGetMockMenu() {
        self.mealDetails.value = MealViewModel(MealDetailsModel.mealDemoData)
    }
}
class MealViewModel {
    var mealDetailsModel: MealDetailsModel?
    var noticesText: [FilterNoticesListCache]?
    var mealCounterDescription: String {
        return mealDetailsModel?.counterDescription ?? ""
    }
    var generalNoticesText: NSAttributedString {
        if let mealDetailsModel = mealDetailsModel, mealDetailsModel.generalNotices.count > 0 {
            if let noticesText = noticesText, noticesText.count > 0 {
                let mutableAttributedString = NSMutableAttributedString()
                for (index, notice) in mealDetailsModel.generalNotices.enumerated() {
                    mutableAttributedString.append(
                        getNoticesAttributedString(selectedNotices: noticesText, notice: notice, listItemNormalStyle: AppStyle.square, listItemWarningStyle: AppStyle.triangle))
                    if index != mealDetailsModel.generalNotices.endIndex {
                        mutableAttributedString.append(NSMutableAttributedString(string: AppStyle.newLine, attributes: AppStyle.regularAttributes))
                    }
                }
                return mutableAttributedString
            } else {
                return NSMutableAttributedString(string: AppStyle.square + mealDetailsModel.generalNotices.map {
                    $0.noticeDispalyName}.joined(separator: AppStyle.newLineSquare),
                                                 attributes: AppStyle.regularAttributes)
            }
        } else {
            return NSMutableAttributedString(string: "", attributes: AppStyle.regularAttributes)
        }
    }
    var mealComponetsText: NSAttributedString {

        //need refactoring
        if  let mealDetailsModel = mealDetailsModel, mealDetailsModel.mealComponets.count > 0 {
            if let noticesText = noticesText, noticesText.count > 0 {
                let mutableAttributedString = NSMutableAttributedString()
                for meal in mealDetailsModel.mealComponets {
                    let componentName = NSMutableAttributedString(string: AppStyle.square + meal.componentName, attributes: AppStyle.regularAttributes)
                    mutableAttributedString.append(componentName)
                    // new line separator should only be between notices, there no need to an extra newline after the last notice
                    for notice in meal.componentNotices {
                        mutableAttributedString.append(
                            getNoticesAttributedString(selectedNotices: noticesText, notice: notice, listItemNormalStyle: AppStyle.BULLET, listItemWarningStyle:
                                AppStyle.newLineTabFLAG))
                    }
                    mutableAttributedString.append(NSMutableAttributedString(string: AppStyle.newLine, attributes: AppStyle.regularAttributes))
                }
                return mutableAttributedString
            } else {
                return NSMutableAttributedString(string: AppStyle.square + mealDetailsModel.mealComponets.map {$0.componentName +
                    $0.componentNotices.map {AppStyle.BULLET + $0.noticeDispalyName }.joined()}.joined(separator: AppStyle.newLineSquare),
                                                 attributes: AppStyle.regularAttributes)
            }
        } else {
            return NSMutableAttributedString(string: "", attributes: AppStyle.regularAttributes)
        }
    }
    var priceTagNamesText: String {
        return mealDetailsModel?.prices.map {$0.priceTagName + "\n"}.joined() ?? ""
    }
    var priceValuesText: String {
        return mealDetailsModel?.prices.map {$0.price + " € \n"}.joined() ?? ""
    }
    var mealName: String {
        return mealDetailsModel?.mealName ?? ""
    }
    func getNoticesAttributedString(selectedNotices: [FilterNoticesListCache], notice: MealNotices, listItemNormalStyle: String, listItemWarningStyle: String)
        -> NSMutableAttributedString {
        let mutableAttributedString = NSMutableAttributedString()
        if selectedNotices.contains(where: {$0.noticeID == notice.noticeTag}) {
            let redNotices = NSMutableAttributedString(string: listItemWarningStyle + notice.noticeDispalyName ,
                                                       attributes: AppStyle.redAttributes)
            mutableAttributedString.append(redNotices)
        } else {
            let normalNotices = NSMutableAttributedString(string: listItemNormalStyle + notice.noticeDispalyName,
                                                          attributes: AppStyle.regularAttributes)
            mutableAttributedString.append(normalNotices)
        }
        return mutableAttributedString
    }
    init(_ mealDetailsModel: MealDetailsModel, noticesText: [FilterNoticesListCache]? = nil) {
        self.mealDetailsModel = mealDetailsModel
        self.noticesText = noticesText
    }

    public init() {
    }
}
