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
    let daysMenus = Bindable([TableViewCellType<MensaDayMenuViewModel>]())
    var isFilterdCacheUpdated = true
    // MARK: - Object Lifecycle
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
   // load mensa menu from APi with the local cached alligern
    func loadGetMensaMenu() {
        showLoadingIndicator.value = true
        Cache.shared.fetchMensaFilterFromStorage()
        dataClient.getMensaMenu(completion: { [weak self] result in
            switch result {
            case .success(let menus):
                guard menus.daysMenus.count > 0 else {
                    self?.daysMenus.value = [.empty]
                    return
                }
                if  AppSessionManager.shared.mensafiltersLastChanged != menus.filtersLastChanged {
                    AppSessionManager.shared.mensafiltersLastChanged = menus.filtersLastChanged
                    self?.isFilterdCacheUpdated = false
                } else {
                    AppSessionManager.shared.isMensaFiltersCacheFetched = true
                }
                self?.daysMenus.value = menus.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0))}
                self?.showLoadingIndicator.value = false
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.daysMenus.value = [.error(message: error?.localizedDescription ?? NSLocalizedString("UnknownError", comment: ""))]
                self?.showError(error: error)
            }
        })
    }
    func loadGetMockMenu() {
        self.daysMenus.value = MensaMenuModel.menuDemoData.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0))}
    }

    func isMenuUpdated() {
        let firstMenuDay = self.daysMenus.value.first
        switch firstMenuDay {
        case .normal(let viewModel):
            // if the view model date is outdate we fire the api call again
            if viewModel.dateValue != getDateFormater(date: Date()) {
                loadGetMensaMenu()
            }
        default :
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
    // MARK: - Instance Properties
    var dateText: NSMutableAttributedString
    var dateValue: String
    var mealsCells: [MensaMealCellViewModel]
    init(mensaDayModel: MensaDayModel) {
        let splitedDate = mensaDayModel.date.split {$0 == " "}
        let mutableAttributedString = NSMutableAttributedString()
        let dayText = String(splitedDate.first ?? "")
        dateValue = String(splitedDate.last ?? "")
        let dayName =  NSMutableAttributedString(string: dayText + " ", attributes: AppStyle.largeTitleAttributes)
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
    // MARK: - Instance Properties
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
                guard let noticeID = item.noticeID else {
                    return false
                }
                return mensaMealsModel.notices.contains(noticeID)
            }
            return intersectionNotices
        }
        return []
    }

    func getSelectedNotices() -> [FilterNoticesListCache]? {
        return  Cache.shared.fetchedResultsController.fetchedObjects?.filter { $0.isSelected}
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
