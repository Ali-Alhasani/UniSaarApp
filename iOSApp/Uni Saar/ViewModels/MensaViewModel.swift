//
//  MensaViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation
import UIKit

@Observable
class MensaMenuViewModel: ParentViewModel {
    var daysMenus: [TableViewCellType<MensaDayMenuViewModel>] = []
    var isFilterdCacheUpdated = false

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMensaMenu() async {
        showLoadingIndicator = true
        Cache.shared.fetchMensaFilterFromStorage()
        do {
            let menus = try await dataClient.getMensaMenu(locationKey: AppSessionManager.shared.selectedMensaLocation.locationKey)
            guard menus.daysMenus.count > 0 else {
                daysMenus = [.empty]
                return
            }
            if AppSessionManager.shared.mensafiltersLastChanged != menus.filtersLastChanged {
                AppSessionManager.shared.mensafiltersLastChanged = menus.filtersLastChanged
                isFilterdCacheUpdated = false
            } else {
                AppSessionManager.shared.isMensaFiltersCacheFetched = true
            }
            daysMenus = menus.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0)) }
            showLoadingIndicator = false
        } catch {
            showLoadingIndicator = false
            daysMenus = [.error(message: error.localizedDescription)]
            showError(error: error, tryAgainHandler: { [weak self] in
                self?.realodGetApi()
            })
        }
    }

    func realodGetApi() {
        Task { await self.loadGetMensaMenu() }
    }

    func loadGetMockMenu() {
        daysMenus = MensaMenuModel.menuDemoData.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0)) }
    }

    func isMenuUpdated() {
        let firstMenuDay = daysMenus.first
        switch firstMenuDay {
        case let .normal(viewModel):
            if viewModel.dateValue != getDateFormater(date: Date()) {
                Task { await self.loadGetMensaMenu() }
            }
        default:
            Task { await self.loadGetMensaMenu() }
        }
    }

    func getDateFormater(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM."
        return formatter.string(from: date)
    }
}

class MensaDayMenuViewModel {
    var dateText: NSMutableAttributedString
    var dateValue: String
    var mealsCells: [MensaMealCellViewModel]
    init(mensaDayModel: MensaDayModel) {
        let splitedDate = mensaDayModel.date.split { $0 == " " }
        let mutableAttributedString = NSMutableAttributedString()
        let dayText = String(splitedDate.first ?? "")
        dateValue = String(splitedDate.last ?? "")
        let dayName = NSMutableAttributedString(string: dayText + " ", attributes: AppStyle.largeTitleAttributes)
        let date = NSMutableAttributedString(string: dateValue, attributes: AppStyle.calloutAttributes)
        mutableAttributedString.append(dayName)
        mutableAttributedString.append(date)
        dateText = mutableAttributedString
        mealsCells = mensaDayModel.countersMeals
    }
}

@MainActor @objc public protocol MensaMenuViewModelView {
    @objc var counterLabel: UILabel? { get }
    @objc optional var mealDisplayNameLabel: UILabel? { get }
    @objc optional var hoursLabel: UILabel? { get }
    @objc optional var mealsLabel: UILabel? { get }
    @objc optional var noticeLabel: UILabel? { get }
    @objc optional var counterColorView: UIView? { get }
}

@MainActor
protocol MensaMealCellViewModel {
    var mensaMealsModel: MensaMealsModel { get }
    var counterDisplayName: String { get }
    var mealName: String { get }
    var openingHoursText: String { get }
    var counterColor: UIColor { get }
    var mealsText: String { get }
    var noticesText: String { get }
    var noticesList: [FilterNoticesListCache] { get }
}

@MainActor
extension MensaMealsModel: MensaMealCellViewModel {
    var mensaMealsModel: MensaMealsModel {
        self
    }

    var counterDisplayName: String {
        counterName
    }

    var mealName: String {
        mealDispalyName
    }

    var openingHoursText: String {
        openiningHours
    }

    var counterColor: UIColor {
        AppStyle.mensaCounterColor(color)
    }

    var mealsText: String {
        meals.compactMap(\.self).joined(separator: "\n")
    }

    @MainActor var noticesList: [FilterNoticesListCache] {
        checkMealNotices()
    }

    @MainActor var noticesText: String {
        if noticesList.count > 0 {
            AppStyle.warningTriangle + NSLocalizedString("contains", comment: "") + noticesList.compactMap(\.name).joined(separator: ", ")
        } else {
            ""
        }
    }

    @MainActor func checkMealNotices() -> [FilterNoticesListCache] {
        let selectedNotices = getSelectedNotices()
        if let selectedNotices, selectedNotices.count > 0 {
            return selectedNotices.filter { item -> Bool in
                guard let noticeID = item.noticeID else { return false }
                return mensaMealsModel.notices.contains(noticeID)
            }
        }
        return []
    }

    @MainActor func getSelectedNotices() -> [FilterNoticesListCache]? {
        Cache.shared.fetchedResultsController.fetchedObjects?.filter(\.isSelected)
    }
}

extension MensaMealCellViewModel {
    public func configure(_ view: MensaMenuViewModelView) {
        view.counterLabel?.text = counterDisplayName
        view.mealDisplayNameLabel??.text = mealName
        view.hoursLabel??.text = openingHoursText
        view.mealsLabel??.text = mealsText
        if noticesText != "" {
            view.counterColorView??.backgroundColor = counterColor.withAlphaComponent(0.2)
        } else {
            view.counterColorView??.backgroundColor = counterColor
        }
        view.noticeLabel??.text = noticesText
    }
}
