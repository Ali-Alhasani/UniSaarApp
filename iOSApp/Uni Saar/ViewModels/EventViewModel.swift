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
        dataClient.getEvents(month: month, year: year, completion: { [weak self] result in
            self?.showLoadingIndicator.value = false
            switch result {
            case .success(let events):
                guard events.newsList.count > 0 else {
                    self?.eventCells.value = [.empty]
                    return
                }
                self?.eventCells.value = events.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel )}
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.eventCells.value = [.error(message: error?.localizedDescription ?? NSLocalizedString("UnknownError", comment: ""))]
                self?.showError(error: error)
            }
        })
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
