//
//  EventViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/17/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
class EventViewModel: ParentViewModel {
    // MARK: - Object Lifecycle
    let eventCells = Bindable([TableViewCellType<NewsFeedCellViewModel>]())
    var selectedDateEvents =  Bindable([TableViewCellType<NewsFeedCellViewModel>]())
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    func loadGetEvents(month: String, year: String) {
        showLoadingIndicator.value = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let events = try await dataClient.getEvents(month: month, year: year)
                showLoadingIndicator.value = false
                guard events.newsList.count > 0 else {
                    eventCells.value = [.empty]
                    return
                }
                eventCells.value = events.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel) }
            } catch {
                showLoadingIndicator.value = false
                eventCells.value = [.error(message: error.localizedDescription)]
                showError(error: error)
            }
        }
    }

    func getDayEvents(day: Date?) {
        selectedDateEvents.value = eventCells.value.filter { (item) -> Bool in
            switch item {
            case .normal(let event):
                if convertDate(strDate: event.newsDate) == day {
                    return true
                }
            default:
                return false
            }
            return false
        }
    }
    func countDayEvents(day: Date) -> Int {
        let events = eventCells.value.filter { (item) -> Bool in
            switch item {
            case .normal(let event):
                if convertDate(strDate: event.newsDate) == day {
                    return true
                }
            default:
                return false
            }
            return false
        }
        return events.count
    }

    func convertDate(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'"
        return dateFormatter.date(from: strDate)
    }

}
