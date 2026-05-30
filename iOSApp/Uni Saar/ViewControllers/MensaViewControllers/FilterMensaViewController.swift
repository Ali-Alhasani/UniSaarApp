//
//  FilterMensaViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/11/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import CoreData
import Combine

protocol FilterMensaViewDelegate: AnyObject {
    func didChangeLocationFilter()
    func didUpdateNoticesFilter()
    func didUpdateNoticesData()
}

class FilterMensaViewController: UIViewController {
    @IBOutlet weak var filterTableView: UITableView! {
        didSet {
            let refreshControl = filterTableView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.refershLoad), for: .valueChanged)
            filterTableView.refreshControl = refreshControl
        }
    }
    lazy var filterMensaViewModel: FilterMensaViewModel = FilterMensaViewModel()
    weak var delegate: FilterMensaViewDelegate?
    private var cancellables = Set<AnyCancellable>()

    private func filterForSectionIndex(_ index: Int) -> FilterMensaViewModel.Filter? {
        return FilterMensaViewModel.Filter(rawValue: index)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        bindViewModel()
        filterMensaViewModel.loadGetFilterList()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppSessionManager.shared.foodAlarmTime = filterMensaViewModel.selectedAlramTime
        AppSessionManager.saveFoodAlarmStatus()
    }

    func setupTableView() {
        filterTableView.register(FilterUISwitchTableViewCell.nib, forCellReuseIdentifier: FilterUISwitchTableViewCell.identifier)
        filterTableView.register(NewMensaNotificationTableViewCell.nib, forCellReuseIdentifier: NewMensaNotificationTableViewCell.identifier)
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.layoutTableView()
        view.backgroundColor = UIColor.flatGray
    }

    func bindViewModel() {
        AppSessionManager.loadFoodAlarmTime()

        filterMensaViewModel.$didUpdatefilterList
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.realodTableView()
            }
            .store(in: &cancellables)

        filterMensaViewModel.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.presentSingleButtonDialog(alert: alert)
            }
            .store(in: &cancellables)

        filterMensaViewModel.$showLoadingIndicator
            .dropFirst()
            .sink { [weak self] visible in
                guard let self else { return }
                visible ? filterTableView.showingLoadingView() : filterTableView.hideLoadingView()
            }
            .store(in: &cancellables)

        filterMensaViewModel.$didUpdateFoodAlarmStatus
            .dropFirst()
            .sink { [weak self] updated in
                guard let self else { return }
                if updated {
                    updateTableView()
                } else {
                    reloadFoodAlramSection()
                }
            }
            .store(in: &cancellables)

        filterMensaViewModel.$selectedAlramTime
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadFoodAlramSection()
            }
            .store(in: &cancellables)
    }

    func realodTableView() {
        filterTableView.reloadData()
    }

    func reloadFoodAlramSection() {
        filterTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    @objc private func refershLoad() {
        filterMensaViewModel.isFilterdCacheUpdated = false
        filterMensaViewModel.loadGetFilterList()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        actionAfterChangeCampus()
        saveContext()
        saveFoodAlramTime()
        if filterMensaViewModel.isFilterdCacheUpdated {
            delegate?.didUpdateNoticesData()
        }
        dismissView()
    }

    func actionAfterChangeCampus() {
        if filterMensaViewModel.mensaLocation != AppSessionManager.shared.selectedMensaLocation {
            AppSessionManager.shared.selectedMensaLocation = filterMensaViewModel.mensaLocation
            delegate?.didChangeLocationFilter()
            dismissView()
        }
    }

    func saveContext() {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                delegate?.didUpdateNoticesFilter()
            } catch {
            }
        }
    }

    func saveFoodAlramTime() {
        if filterMensaViewModel.isFoodAlarmEnabled {
            saveUserSelctedTime()
        }
    }

    func dismissView() {
        dismiss(animated: true)
    }

    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toNotificationTime = "NotificationTime"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toNotificationTime,
           let destinationViewController = segue.destination as? NotificationTimeViewController {
            destinationViewController.selectedTime = filterMensaViewModel.selectedAlramTime
            destinationViewController.delegate = self
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FilterMensaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filter = filterForSectionIndex(section) {
            return filterMensaViewModel.filterList(for: filter).count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if let priority = filterForSectionIndex(indexPath.section) {
            switch priority {
            case .location:
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                var content = cell.defaultContentConfiguration()
                content.text = item?.filterName
                cell.contentConfiguration = content
                if item?.filterID == filterMensaViewModel.mensaLocation.locationKey {
                    cell.accessoryType = .checkmark
                }
            case .allergenList:
                let allergenCell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as? FilterUISwitchTableViewCell
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                allergenCell?.cellTitle = item?.filterName
                allergenCell?.indexPath = indexPath
                allergenCell?.switchValue = item?.isSelected
                allergenCell?.mensaDelegate = self
                allergenCell?.selectionStyle = .none
                return allergenCell ?? cell
            case .empty:
                return cell
            case .foodAlram:
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                if item?.filterID == "1" {
                    let alramCell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as? FilterUISwitchTableViewCell
                    alramCell?.cellTitle = item?.filterName
                    alramCell?.indexPath = indexPath
                    alramCell?.switchValue = item?.isSelected
                    alramCell?.mensaDelegate = self
                    return alramCell ?? cell
                } else {
                    return setFoodAlramCell(tableView, indexPath, cell)
                }
            }
        }
        return cell
    }

    func setFoodAlramCell(_ tableView: UITableView, _ indexPath: IndexPath, _ cell: UITableViewCell) -> UITableViewCell {
        let alramCell = tableView.dequeueReusableCell(withIdentifier: NewMensaNotificationTableViewCell.identifier, for: indexPath) as? NewMensaNotificationTableViewCell
        alramCell?.notificationSelectedTime = filterMensaViewModel.selectedAlramTime
        alramCell?.delegate = self
        return alramCell ?? cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return FilterMensaViewModel.Filter.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        if let priority = filterForSectionIndex(section) {
            switch priority {
            case .location:
                title = NSLocalizedString("MensaLocations", comment: "")
            case .empty:
                title = NSLocalizedString("WarnMeAbout", comment: "")
            case .allergenList:
                break
            case .foodAlram:
                title = NSLocalizedString("MensaNotifications", comment: "")
            }
        }
        return title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var title: String = ""
        if let priority = filterForSectionIndex(section) {
            switch priority {
            case .location:
                break
            case .empty:
                title = NSLocalizedString("HighlightAllergens", comment: "")
            case .allergenList:
                break
            case .foodAlram:
                break
            }
        }
        return title
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            let locationItems = filterMensaViewModel.filterList(for: .location)
            if let location = locationItems[safe: indexPath.row] {
                filterMensaViewModel.mensaLocation = Campus(rawValue: location.filterID) ?? Campus.saarbruken
                filterTableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
                actionAfterChangeCampus()
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 1 && filterMensaViewModel.isFoodAlarmEnabled == false {
            return 0.0
        }
        return getDefultHieght(indexPath, tableview: tableView)
    }

    func getDefultHieght(_ indexPath: IndexPath, tableview: UITableView) -> CGFloat {
        return tableview.rowHeight
    }
}

extension FilterMensaViewController: SingleButtonDialogPresenter { }

extension FilterMensaViewController: MensaFilterCellDelegate {
    func didSwitchOnFilter(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            if indexPath.section == 1 {
                filterMensaViewModel.checkNotificationStatus()
            } else {
                let noticeEntry = Cache.shared.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
                let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: noticeEntry.objectID) as? FilterNoticesListCache
                childEntry?.isSelected = true
            }
        }
    }

    func didSwitchOffFilter(indexPath: IndexPath?) {
        if let indexPath = indexPath {
            if indexPath.section == 1 {
                filterMensaViewModel.isFoodAlarmEnabled = false
                updateTableView()
            } else {
                let noticeEntry = Cache.shared.fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0))
                let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: noticeEntry.objectID) as? FilterNoticesListCache
                childEntry?.isSelected = false
            }
        }
    }
}

extension FilterMensaViewController: NotificationTimeDelegate {
    func tmpSelectedTime(time: Date) {
        filterMensaViewModel.tmpSelectedAlramTime = time
    }

    func saveUserSelctedTime() {
        filterMensaViewModel.selectedAlramTime = filterMensaViewModel.tmpSelectedAlramTime
        filterMensaViewModel.cancelNotification()
        filterMensaViewModel.scheduleNotification()
        filterMensaViewModel.tmpSelectedAlramTime = nil
    }

    func updateTableView() {
        filterTableView.performBatchUpdates(nil)
    }

    func selectedTime(time: Date) {
        filterMensaViewModel.selectedAlramTime = time
        updateTableView()
        filterMensaViewModel.cancelNotification()
        filterMensaViewModel.scheduleNotification()
    }
}
