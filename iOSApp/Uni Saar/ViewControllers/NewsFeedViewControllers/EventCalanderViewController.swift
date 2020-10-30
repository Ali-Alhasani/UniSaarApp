//
//  EventCalanderViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import FSCalendar
class EventCalanderViewController: UIViewController {
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            DispatchQueue.main.async {
                let refreshControl = self.tableView.setUpRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.load), for: UIControl.Event.valueChanged)
                self.tableView.refreshControl = refreshControl
            }
        }
    }
    lazy var eventViewModel: EventViewModel = EventViewModel()
    // date format
    fileprivate let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    fileprivate let gregorian: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpCalander()
        setupTableView()
        DispatchQueue.main.async {
            self.bindViewModel()
            self.load()
        }
    }
    func setUpCalander() {
        calendar.delegate = self
        calendar.dataSource = self
        // custom color for the calendar view
        self.view.backgroundColor = UIColor.flatGray
        calendar.appearance.titleDefaultColor = UIColor.labelCustomColor
        calendar.appearance.headerTitleColor = UIColor.labelCustomColor
        calendar.appearance.weekdayTextColor = UIColor.labelCustomColor
    }

    @objc func load() {
        let currentCalendarDate = getCurrentDate()
        eventViewModel.loadGetEvents(month: currentCalendarDate.month,
                                     year: currentCalendarDate.year)
    }
    func getCurrentDate() -> (month: String, year: String) {
        return (month: String(Calendar.current.component(.month, from: calendar.currentPage)), year : String(Calendar.current.component(.year, from: calendar.currentPage)))
    }
    func setupTableView() {
        tableView.register(NewsFeedTableViewCell.nib, forCellReuseIdentifier: NewsFeedTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layoutTableView()
    }
    func bindViewModel() {
        eventViewModel.eventCells.bind { [weak self] _ in
            if let `self` = self {
                self.eventViewModel.getDayEvents(day: self.calendar.today)
                self.calendar.reloadData()
            }
        }
        eventViewModel.selectedDateEvents.bind { [weak self] _ in
            if let `self` = self {
                self.reloadTableView()
            }
        }
        eventViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        eventViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.tableView.showingLoadingView() : self.tableView.hideLoadingView()
            }
        }
    }
    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func getNumberOfEvents (date: Date) -> Int {
        return eventViewModel.countDayEvents(day: date)
    }

    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toEventDetails = "toEventsReader"
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueIdentifiers.toEventDetails, let destination = segue.destination as? UINavigationController,
            let destinationViewController = destination.topViewController as? NewsReaderViewController,
            let viewModel = sender as? NewsFeedCellViewModel {
            destinationViewController.newsItemViewModel = viewModel
        }
    }
}
// MARK: - FSCalendarDelegate
extension EventCalanderViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        //print("change page to \(self.formatter.string(from: calendar.currentPage))")
        load()
        self.eventViewModel.selectedDateEvents.value.removeAll()
        reloadTableView()
    }
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        //print("calendar did select date \(self.formatter.string(from: date))")
        if monthPosition == .previous || monthPosition == .next {
            // user has chosen a day from another month
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
        return eventViewModel.selectedDateEvents.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        switch eventViewModel.selectedDateEvents.value[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.identifier, for: indexPath) as? NewsFeedTableViewCell else {
                return defaultCell
            }
            viewModel.configure(cell)
            if let imageURL = viewModel.imageURL {
                // async download
                cell.newsImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "SF_arrow_2_circlepath_circle_fill"), completion: { response in
                    // Check if the image isn't already cached
                    if response.response != nil {
                        // Force the cell update
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
        switch eventViewModel.selectedDateEvents.value[safe: indexPath.row] {
        case .normal(let viewModel):
            self.performSegue(withIdentifier: SegueIdentifiers.toEventDetails, sender: viewModel)
        case .empty, .error, .none:
            // nop
            break
        }
    }

}
extension EventCalanderViewController: SingleButtonDialogPresenter { }
