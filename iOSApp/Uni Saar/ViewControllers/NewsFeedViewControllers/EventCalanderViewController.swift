//
//  EventCalanderViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import FSCalendar
import Observation

@MainActor
class EventCalanderViewController: UIViewController {
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            let refreshControl = tableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.load), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }
    lazy var eventViewModel: EventViewModel = EventViewModel()

    fileprivate let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCalander()
        setupTableView()
        observeEventCells()
        observeSelectedDayEvents()
        load()
    }

    func setUpCalander() {
        calendar.delegate = self
        calendar.dataSource = self
        view.backgroundColor = UIColor.flatGray
        calendar.appearance.titleDefaultColor = UIColor.labelCustomColor
        calendar.appearance.headerTitleColor = UIColor.labelCustomColor
        calendar.appearance.weekdayTextColor = UIColor.labelCustomColor
    }

    @objc func load() {
        let currentCalendarDate = getCurrentDate()
        Task { [weak self] in await self?.eventViewModel.loadGetEvents(month: currentCalendarDate.month, year: currentCalendarDate.year) }
    }

    func getCurrentDate() -> (month: String, year: String) {
        return (month: String(Calendar.current.component(.month, from: calendar.currentPage)),
                year: String(Calendar.current.component(.year, from: calendar.currentPage)))
    }

    func setupTableView() {
        tableView.register(NewsFeedTableViewCell.nib, forCellReuseIdentifier: NewsFeedTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layoutTableView()
    }

    private func observeEventCells() {
        withObservationTracking {
            _ = eventViewModel.eventCells
            _ = eventViewModel.currentAlert
            eventViewModel.getDayEvents(day: calendar.today)
            calendar.reloadData()
            eventViewModel.showLoadingIndicator ? tableView.showingLoadingView() : tableView.hideLoadingView()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let alert = eventViewModel.currentAlert {
                    eventViewModel.currentAlert = nil
                    presentSingleButtonDialog(alert: alert)
                }
                observeEventCells()
            }
        }
    }

    private func observeSelectedDayEvents() {
        withObservationTracking {
            _ = eventViewModel.selectedDateEvents
            tableView.reloadData()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.observeSelectedDayEvents() }
        }
    }

    func getNumberOfEvents(date: Date) -> Int {
        return eventViewModel.countDayEvents(day: date)
    }

    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toEventDetails = "toEventsReader"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toEventDetails,
           let destination = segue.destination as? UINavigationController,
           let destinationViewController = destination.topViewController as? NewsReaderViewController,
           let viewModel = sender as? NewsFeedCellViewModel {
            destinationViewController.newsItemViewModel = viewModel
        }
    }
}

// MARK: - FSCalendarDelegate
extension EventCalanderViewController: @preconcurrency FSCalendarDelegate, @preconcurrency FSCalendarDataSource {
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        load()
        eventViewModel.selectedDateEvents = []
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            eventViewModel.getDayEvents(day: date)
        }
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        return getNumberOfEvents(date: date)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension EventCalanderViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventViewModel.selectedDateEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch eventViewModel.selectedDateEvents[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.identifier, for: indexPath) as? NewsFeedTableViewCell else {
                return defaultCell
            }
            viewModel.configure(cell)
            if let imageURL = viewModel.imageURL {
                cell.newsImageView.af.setImage(withURL: imageURL, placeholderImage: UIImage(systemName: "arrow.2.circlepath.circle.fill"), completion: { response in
                    if response.response != nil {
                        self.tableView.reloadRowAt()
                    }
                })
            }
            cell.selectionStyle = .none
            return cell
        case .error(let message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyEvents", comment: ""))
        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch eventViewModel.selectedDateEvents[safe: indexPath.row] {
        case .normal(let viewModel):
            performSegue(withIdentifier: SegueIdentifiers.toEventDetails, sender: viewModel)
        case .empty, .error, .none:
            break
        }
    }
}

extension EventCalanderViewController: SingleButtonDialogPresenter { }
