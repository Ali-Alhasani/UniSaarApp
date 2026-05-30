//
//  MensaViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

class MensaMenuViewModel: ParentViewModel {
    @Published var daysMenus: [TableViewCellType<MensaDayMenuViewModel>] = []
    var isFilterdCacheUpdated = false

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMensaMenu() {
        showLoadingIndicator = true
        Cache.shared.fetchMensaFilterFromStorage()
        Task { [weak self] in
            guard let self else { return }
            do {
                let menus = try await dataClient.getMensaMenu()
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
    }

    func realodGetApi() {
        loadGetMensaMenu()
    }

    func loadGetMockMenu() {
        daysMenus = MensaMenuModel.menuDemoData.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0)) }
    }

    func isMenuUpdated() {
        let firstMenuDay = daysMenus.first
        switch firstMenuDay {
        case .normal(let viewModel):
            if viewModel.dateValue != getDateFormater(date: Date()) {
                loadGetMensaMenu()
            }
        default:
            loadGetMensaMenu()
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
        let splitedDate = mensaDayModel.date.split {$0 == " "}
        let mutableAttributedString = NSMutableAttributedString()
        let dayText = String(splitedDate.first ?? "")
        dateValue = String(splitedDate.last ?? "")
        let dayName = NSMutableAttributedString(string: dayText + " ", attributes: AppStyle.largeTitleAttributes)
        let date = NSMutableAttributedString(string: dateValue, attributes: AppStyle.calloutAttributes)
        mutableAttributedString.append(dayName)
        mutableAttributedString.append(date)
        self.dateText = mutableAttributedString
        self.mealsCells = mensaDayModel.countersMeals
    }
}

@objc public protocol MensaMenuViewModelView {
    @objc var counterLabel: UILabel? { get }
    @objc optional var mealDisplayNameLabel: UILabel? { get }
    @objc optional var hoursLabel: UILabel? { get }
    @objc optional var mealsLabel: UILabel? { get }
    @objc optional var noticeLabel: UILabel? { get }
    @objc optional var counterColorView: UIView? { get}
}

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

extension MensaMealsModel: MensaMealCellViewModel {
    var mensaMealsModel: MensaMealsModel {
        return self
    }
    var counterDisplayName: String {
        return counterName
    }
    var mealName: String {
        return mealDispalyName
    }
    var openingHoursText: String {
        return openiningHours
    }
    var counterColor: UIColor {
        return AppStyle.mensaCounterColor(color)
    }
    var mealsText: String {
        return meals.compactMap {$0}.joined(separator: "\n")
    }
    var noticesList: [FilterNoticesListCache] {
        return checkMealNotices()
    }
    var noticesText: String {
        if noticesList.count > 0 {
            return AppStyle.warningTriangle + NSLocalizedString("contains", comment: "") + noticesList.compactMap {$0.name}.joined(separator: ", ")
        } else {
            return ""
        }
    }

    func checkMealNotices() -> [FilterNoticesListCache] {
        let selectedNotices = getSelectedNotices()
        if let selectedNotices = selectedNotices, selectedNotices.count > 0 {
            let intersectionNotices = selectedNotices.filter { (item) -> Bool in
                guard let noticeID = item.noticeID else { return false }
                return mensaMealsModel.notices.contains(noticeID)
            }
            return intersectionNotices
        }
        return []
    }

    func getSelectedNotices() -> [FilterNoticesListCache]? {
        return Cache.shared.fetchedResultsController.fetchedObjects?.filter { $0.isSelected }
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
