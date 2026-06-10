//
//  EventCalanderViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import FSCalendar
import UIKit

@MainActor
class EventCalanderViewController: UIViewController {
    @IBOutlet var calendar: FSCalendar!
    @IBOutlet var tableView: UITableView! {
        didSet {
            let refreshControl = tableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(load), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }

    lazy var eventViewModel: EventViewModel = .init()

    fileprivate let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCalander()
        setupTableView()
        load()
    }

    override func updateProperties() {
        updateUI()
    }

    private func updateUI() {
        if eventViewModel.showLoadingIndicator { tableView.showingLoadingView() } else { tableView.hideLoadingView() }
        if let alert = eventViewModel.currentAlert {
            Task { @MainActor [weak self] in
                guard let self else { return }
                eventViewModel.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }
        calendar.reloadData()
        tableView.reloadData()
        if !eventViewModel.eventCells.isEmpty, eventViewModel.selectedDateEvents.isEmpty {
            Task { @MainActor [weak self] in
                self?.eventViewModel.getDayEvents(day: self?.calendar.today)
            }
        }
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
        (month: String(Calendar.current.component(.month, from: calendar.currentPage)),
         year: String(Calendar.current.component(.year, from: calendar.currentPage)))
    }

    func setupTableView() {
        tableView.register(NewsFeedTableViewCell.nib, forCellReuseIdentifier: NewsFeedTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layoutTableView()
    }

    func getNumberOfEvents(date: Date) -> Int {
        eventViewModel.countDayEvents(day: date)
    }

    // MARK: - Navigation

    enum SegueIdentifiers {
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
        getNumberOfEvents(date: date)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension EventCalanderViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        eventViewModel.selectedDateEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch eventViewModel.selectedDateEvents[safe: indexPath.row] {
        case let .normal(viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.identifier, for: indexPath) as? NewsFeedTableViewCell else {
                return defaultCell
            }
            cell.configure(with: viewModel)
            if let imageURL = viewModel.imageURL {
                cell.newsImageView.af.setImage(withURL: imageURL, placeholderImage: UIImage(systemName: "arrow.2.circlepath.circle.fill"), completion: { [weak self] response in
                    if response.response != nil {
                        self?.tableView.reloadRowAt()
                    }
                })
            }
            cell.selectionStyle = .none
            return cell
        case let .error(message):
            return defaultCell.setupEmptyCell(message: message)
        case .empty:
            return defaultCell.setupEmptyCell(message: NSLocalizedString("EmptyEvents", comment: ""))
        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch eventViewModel.selectedDateEvents[safe: indexPath.row] {
        case let .normal(viewModel):
            performSegue(withIdentifier: SegueIdentifiers.toEventDetails, sender: viewModel)
        case .empty, .error, .none:
            break
        }
    }
}

extension EventCalanderViewController: SingleButtonDialogPresenter {}
