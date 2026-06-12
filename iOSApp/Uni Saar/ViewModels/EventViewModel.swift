//
//  EventViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/17/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

@Observable
class EventViewModel: ParentViewModel {
    var eventCells: [TableViewCellType<NewsFeedCellViewModel>] = []
    var selectedDateEvents: [TableViewCellType<NewsFeedCellViewModel>] = []
    @ObservationIgnored private(set) var currentSelectedDate: Date?

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetEvents(month: String, year: String) async {
        showLoadingIndicator = true
        do {
            let events = try await dataClient.getEvents(month: month, year: year)
            showLoadingIndicator = false
            guard events.newsList.count > 0 else {
                eventCells = [.empty]
                return
            }
            eventCells = events.newsList.compactMap { .normal(cellViewModel: $0 as NewsFeedCellViewModel) }
            getDayEvents(day: currentSelectedDate ?? Calendar.current.startOfDay(for: Date()))
        } catch is CancellationError {
            showLoadingIndicator = false
        } catch {
            showLoadingIndicator = false
            eventCells = [.error(message: error.localizedDescription)]
            showError(error: error)
        }
    }

    func getDayEvents(day: Date?) {
        currentSelectedDate = day
        selectedDateEvents = eventCells.filter { item -> Bool in
            switch item {
            case let .normal(event):
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
        let events = eventCells.filter { item -> Bool in
            switch item {
            case let .normal(event):
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
