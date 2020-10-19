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
    // MARK: - Object Lifecycle
    let didUpdatefilterList: Bindable = Bindable(false)
    let didUpdateFoodAlarmStatus: Bindable = Bindable(false)
    var isFilterdCacheUpdated: Bool = false
    var isFoodAlarmEnabled: Bool = false {
        didSet {
            AppSessionManager.shared.isFoodAlarmEnabled = isFoodAlarmEnabled
        }
    }
    var selectedAlramTime: Bindable = Bindable<Date?>(nil) {
        didSet {
            AppSessionManager.shared.foodAlarmTime = selectedAlramTime.value
        }
    }
    enum Filter: Int, CaseIterable {
        case location, foodAlram, empty, allergenList
    }
    // value 7 and 1 for Saturday and Sunday.
    let workingDays = [2, 3, 4, 5, 6]
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    var mensaLocation = AppSessionManager.shared.selectedMensaLocation
    var selectedNotices = [FilterElement]()
    //private var fetchedRC: NSFetchedResultsController<FilterNoticesListCache>!
    func loadGetFilterList() {
        showLoadingIndicator.value = true
        loadFoodAlarmStatus()
        if isFilterdCacheUpdated { // check if the filter date has not been updated from the server
            if !AppSessionManager.shared.isMensaFiltersCacheFetched { //  check if the cache date has not been fetched yet from the core date in this session
                //
                AppSessionManager.shared.isMensaFiltersCacheFetched = true
            }
            showLoadingIndicator.value = false
            // notify FilterMensaViewController
            self.didUpdatefilterList.value = true
        } else {

            dataClient.getMensaFilter(completion: { [weak self] result in
                self?.showLoadingIndicator.value = false

                switch result {
                case .success(let list):
                    let viewModelList = FilterLocationCellViewModel(mensaFilterModel: list)
                    if let self = self {
                        viewModelList.noticesText = self.getOldSelectedNotices(newViewModel: viewModelList)
                        // remove last stored cache before saving the new data
                        self.dataClient.clearFilterCache()
                        self.dataClient.saveInCoreDataWith(model: viewModelList)
                        self.isFilterdCacheUpdated = true
                        Cache.shared.fetchMensaFilterFromStorage()
                        // notify FilterMensaViewController
                        self.didUpdatefilterList.value = true
                        AppSessionManager.shared.isMensaFiltersCacheFetched = true
                    }
                case .failure(let error):
                    self?.showLoadingIndicator.value = false
                    self?.showError(error: error)
                }
            })
        }

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
            return [FilterElement(filterName: NSLocalizedString("EnableFoodAlarm", comment: "") ,
                                  filterID: "1", isSelected: isFoodAlarmEnabled), FilterElement(filterName: "", filterID: "2", isSelected: false)]
        }
    }

    func getOldSelectedNotices(newViewModel: FilterLocationCellViewModel) -> [FilterElement] {
        // get the last cached selected notices before update the new notice name or id
        let oldSelectedNotices =  Cache.shared.fetchedResultsController.fetchedObjects?.filter {$0.isSelected}.map {$0.noticeID}
        //if there are no previous selected notices just return the updated list from the server as it
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
            let date = selectedAlramTime.value ?? someDateTime ?? Date()
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
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.enableNotification()
                self.updateSwitchButton()
            } else if settings.authorizationStatus != .authorized {
                self.updateSwitchButton()
                self.notificationAlert()
            } else {
                self.updateSwitchButton(switchOn: true)
            }
        }
    }

    func updateSwitchButton(switchOn: Bool = false) {
        DispatchQueue.main.async {
            self.didUpdateFoodAlarmStatus.value = switchOn
            self.isFoodAlarmEnabled = switchOn
            if switchOn {
                self.scheduleNotification()
            } else {
                self.cancelNotification()
            }
        }
    }

    func enableNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.updateSwitchButton(switchOn: true)
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    func notificationAlert() {
        self.showError(error: LLError(status: true, message: NSLocalizedString("enableNotification", comment: "")))
    }

    func loadFoodAlarmStatus() {
        self.isFoodAlarmEnabled = AppSessionManager.shared.isFoodAlarmEnabled
        if let alarmSavedTime = AppSessionManager.shared.foodAlarmTime {
            self.selectedAlramTime.value = alarmSavedTime
        }
    }
}
class FilterLocationCellViewModel {
    // MARK: - Instance Properties
    var locationsText = [FilterElement]()
    var noticesText = [FilterElement]()
    init(mensaFilterModel: MensaFilterModel) {
        locationsText = mensaFilterModel.locations.map {FilterElement(filterName: $0.name, filterID: $0.locationID, isSelected: false)}
        noticesText = mensaFilterModel.notices.map {FilterElement(filterName: $0.name, filterID: $0.noticeID, isSelected: false)}
    }
    init() {
    }
}
