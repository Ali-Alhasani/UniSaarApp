//
//  MealDetailsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

@Observable
class MealDetailsViewModel: ParentViewModel {
    var mealDetails: MealViewModel = .init()
    var noticesText: [FilterNoticesListCache]?

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMealDetails(mealId: Int) async {
        showLoadingIndicator = true
        do {
            let meal = try await dataClient.getMealDetails(mealId: mealId)
            showLoadingIndicator = false
            mealDetails = MealViewModel(meal, noticesText: noticesText)
        } catch {
            showLoadingIndicator = false
            showError(error: error)
        }
    }

    func loadGetMockMenu() {
        mealDetails = MealViewModel(MealDetailsModel.mealDemoData)
    }
}

struct NoticeItem {
    let text: String
    let isWarning: Bool
}

struct MealComponentItem {
    let name: String
    let notices: [NoticeItem]
}

class MealViewModel {
    var mealDetailsModel: MealDetailsModel?
    var noticesText: [FilterNoticesListCache]?

    var mealName: String {
        mealDetailsModel?.mealName ?? ""
    }

    var mealCounterDescription: String {
        mealDetailsModel?.counterDescription ?? ""
    }

    var priceTagNamesText: String {
        mealDetailsModel?.prices.map { $0.priceTagName + "\n" }.joined() ?? ""
    }

    var priceValuesText: String {
        mealDetailsModel?.prices.map { $0.price + " € \n" }.joined() ?? ""
    }

    var generalNoticeItems: [NoticeItem] {
        guard let mealDetailsModel, !mealDetailsModel.generalNotices.isEmpty else { return [] }
        return mealDetailsModel.generalNotices.map { notice in
            NoticeItem(
                text: notice.noticeDispalyName,
                isWarning: noticesText?.contains(where: { $0.noticeID == notice.noticeTag }) == true
            )
        }
    }

    var mealComponentItems: [MealComponentItem] {
        guard let mealDetailsModel, !mealDetailsModel.mealComponets.isEmpty else { return [] }
        return mealDetailsModel.mealComponets.map { meal in
            MealComponentItem(
                name: meal.componentName,
                notices: meal.componentNotices.map { notice in
                    NoticeItem(
                        text: notice.noticeDispalyName,
                        isWarning: noticesText?.contains(where: { $0.noticeID == notice.noticeTag }) == true
                    )
                }
            )
        }
    }

    init(_ mealDetailsModel: MealDetailsModel, noticesText: [FilterNoticesListCache]? = nil) {
        self.mealDetailsModel = mealDetailsModel
        self.noticesText = noticesText
    }

    init() {}
}
