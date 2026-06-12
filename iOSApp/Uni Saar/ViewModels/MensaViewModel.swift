//
//  MensaViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

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
            if daysMenus.isEmpty {
                daysMenus = [.error(message: error.localizedDescription)]
            }
            showError(error: error)
        }
    }

    func realodGetApi() {
        Task { [weak self] in await self?.loadGetMensaMenu() }
    }

    func loadGetMockMenu() {
        daysMenus = MensaMenuModel.menuDemoData.daysMenus.compactMap { .normal(cellViewModel: MensaDayMenuViewModel(mensaDayModel: $0)) }
    }

    func isMenuUpdated() {
        guard case let .normal(viewModel) = daysMenus.first else { return }
        if viewModel.dateValue != getDateFormater(date: Date()) {
            Task { [weak self] in await self?.loadGetMensaMenu() }
        }
    }

    func getDateFormater(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.MM."
        return formatter.string(from: date)
    }
}

class MensaDayMenuViewModel {
    let dayName: String
    let dateValue: String
    var mealsCells: [MensaMealCellViewModel]
    init(mensaDayModel: MensaDayModel) {
        let splitedDate = mensaDayModel.date.split { $0 == " " }
        dayName = String(splitedDate.first ?? "")
        dateValue = String(splitedDate.last ?? "")
        mealsCells = mensaDayModel.countersMeals
    }
}

struct MensaColor: Equatable {
    let red: Float
    let green: Float
    let blue: Float
}

@MainActor
protocol MensaMealCellViewModel {
    var mensaMealsModel: MensaMealsModel { get }
    var counterDisplayName: String { get }
    var mealName: String { get }
    var openingHoursText: String { get }
    var colorModel: MensaColor { get }
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

    var colorModel: MensaColor {
        MensaColor(red: color.red, green: color.green, blue: color.blue)
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
