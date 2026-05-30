//
//  FilterMensaViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
import NotificationCenter
import UserNotifications

class FilterMensaViewModel: ParentViewModel {
    @Published var didUpdatefilterList: Bool = false
    @Published var didUpdateFoodAlarmStatus: Bool = false
    @Published var selectedAlramTime: Date? = nil {
        didSet {
            AppSessionManager.shared.foodAlarmTime = selectedAlramTime
        }
    }
    var isFilterdCacheUpdated: Bool = false
    var isFoodAlarmEnabled: Bool = false {
        didSet {
            AppSessionManager.shared.isFoodAlarmEnabled = isFoodAlarmEnabled
        }
    }
    var tmpSelectedAlramTime: Date?

    enum Filter: Int, CaseIterable {
        case location, foodAlram, empty, allergenList
    }
    let workingDays = [2, 3, 4, 5, 6]

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
        Cache.shared.fetchMensaFilterFromStorage()
    }

    var mensaLocation = AppSessionManager.shared.selectedMensaLocation
    var selectedNotices = [FilterElement]()

    func loadGetFilterList() {
        showLoadingIndicator = true
        loadFoodAlarmStatus()
        if isFilterdCacheUpdated {
            if !AppSessionManager.shared.isMensaFiltersCacheFetched {
                AppSessionManager.shared.isMensaFiltersCacheFetched = true
            }
            showLoadingIndicator = false
            didUpdatefilterList = true
        } else {
            Task { [weak self] in
                guard let self else { return }
                do {
                    let list = try await dataClient.getMensaFilter()
                    showLoadingIndicator = false
                    let viewModelList = FilterLocationCellViewModel(mensaFilterModel: list)
                    viewModelList.noticesText = getOldSelectedNotices(newViewModel: viewModelList)
                    dataClient.clearFilterCache()
                    dataClient.saveInCoreDataWith(model: viewModelList)
                    isFilterdCacheUpdated = true
                    Cache.shared.fetchMensaFilterFromStorage()
                    didUpdatefilterList = true
                    AppSessionManager.shared.isMensaFiltersCacheFetched = true
                } catch {
                    showLoadingIndicator = false
                    didUpdatefilterList = false
                    showError(error: error, tryAgainHandler: { [weak self] in
                        self?.reloadGetApi()
                    })
                }
            }
        }
    }

    func reloadGetApi() {
        loadGetFilterList()
    }

    func filterList(for fliter: Filter) -> [FilterElement] {
        switch fliter {
        case .location:
            return Cache.shared.fetchedLocationResultsController.fetchedObjects?.compactMap {
                FilterElement(filterName: $0.name ?? "", filterID: $0.locationID ?? "", isSelected: false) } ?? []
        case .allergenList:
            return Cache.shared.fetchedResultsController.fetchedObjects?.compactMap {
                FilterElement(filterName: $0.name ?? "", filterID: $0.noticeID ?? "", isSelected: $0.isSelected) } ?? []
        case .empty:
            return []
        case .foodAlram:
            return [FilterElement(filterName: NSLocalizedString("EnableFoodAlarm", comment: ""),
                                  filterID: "1", isSelected: isFoodAlarmEnabled), FilterElement(filterName: "", filterID: "2",
                                                                                                isSelected: false)]
        }
    }

    func getOldSelectedNotices(newViewModel: FilterLocationCellViewModel) -> [FilterElement] {
        let oldSelectedNotices = Cache.shared.fetchedResultsController.fetchedObjects?.filter {$0.isSelected}.map {$0.noticeID}
        guard let selectedNotices = oldSelectedNotices, selectedNotices.count > 0 else {
            return newViewModel.noticesText
        }
        var intersectionNotices = [FilterElement]()
        for notice in newViewModel.noticesText {
            if selectedNotices.contains(notice.filterID) {
                intersectionNotices.append((filterName: notice.filterName, filterID: notice.filterID, isSelected: true))
            } else {
                intersectionNotices.append(notice)
            }
        }
        return intersectionNotices
    }
}

extension FilterMensaViewModel {
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("TodayMensa", comment: "")
        content.body = NSLocalizedString("NotificationBody", comment: "")
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let someDateTime = formatter.date(from: "11:15")

        for dayValue in workingDays {
            let date = selectedAlramTime ?? someDateTime ?? Date()
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour ?? 11
            dateComponents.minute = components.minute ?? 15
            dateComponents.timeZone = TimeZone.current
            dateComponents.weekday = dayValue
            dateComponents.calendar = Calendar.current
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "MensaNotifcation\(dayValue)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        var notificationNames = ["MensaNotifcation"]
        for dayValue in workingDays {
            notificationNames.append("MensaNotifcation\(dayValue)")
        }
        center.removePendingNotificationRequests(withIdentifiers: notificationNames)
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if settings.authorizationStatus == .notDetermined {
                    enableNotification()
                    updateSwitchButton()
                } else if settings.authorizationStatus != .authorized {
                    updateSwitchButton()
                    notificationAlert()
                } else {
                    updateSwitchButton(switchOn: true)
                }
            }
        }
    }

    func updateSwitchButton(switchOn: Bool = false) {
        didUpdateFoodAlarmStatus = switchOn
        isFoodAlarmEnabled = switchOn
        if switchOn {
            scheduleNotification()
        } else {
            cancelNotification()
        }
    }

    func enableNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] success, error in
            Task { @MainActor [weak self] in
                if success {
                    self?.updateSwitchButton(switchOn: true)
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func notificationAlert() {
        showError(error: LLError(status: true, message: NSLocalizedString("enableNotification", comment: "")))
    }

    func loadFoodAlarmStatus() {
        isFoodAlarmEnabled = AppSessionManager.shared.isFoodAlarmEnabled
        if let alarmSavedTime = AppSessionManager.shared.foodAlarmTime {
            selectedAlramTime = alarmSavedTime
        }
    }
}

class FilterLocationCellViewModel {
    var locationsText = [FilterElement]()
    var noticesText = [FilterElement]()
    init(mensaFilterModel: MensaFilterModel) {
        locationsText = mensaFilterModel.locations.map {FilterElement(filterName: $0.name, filterID: $0.locationID, isSelected: false)}
        noticesText = mensaFilterModel.notices.map {FilterElement(filterName: $0.name, filterID: $0.noticeID, isSelected: false)}
    }
    init() { }
}
