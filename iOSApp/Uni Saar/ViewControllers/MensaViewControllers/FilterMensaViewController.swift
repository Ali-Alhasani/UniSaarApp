//
//  FilterMensaViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/11/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import CoreData
protocol FilterMensaViewDelegate: class {
    func didChangeLocationFilter()
    func didUpdateNoticesFilter()
    func didUpdateNoticesData()
}
class FilterMensaViewController: UIViewController {
    @IBOutlet weak var filterTableView: UITableView! {
        didSet {
            DispatchQueue.main.async {
                let refreshControl = self.filterTableView.setUpRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.refershLoad), for: UIControl.Event.valueChanged)
                self.filterTableView.refreshControl = refreshControl
            }
        }
    }
    // MARK: - Instance Properties
    lazy var filterMensaViewModel: FilterMensaViewModel = FilterMensaViewModel()
    weak var delegate: FilterMensaViewDelegate?
    private func filterForSectionIndex(_ index: Int) -> FilterMensaViewModel.Filter? {
        return FilterMensaViewModel.Filter(rawValue: index)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
        bindViewModel()
        filterMensaViewModel.loadGetFilterList()

    }

    override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           AppSessionManager.shared.foodAlarmTime = filterMensaViewModel.selectedAlramTime.value
           AppSessionManager.saveFoodAlarmStatus()
    }
    func setupTableView() {
        filterTableView.register(FilterUISwitchTableViewCell.nib, forCellReuseIdentifier: FilterUISwitchTableViewCell.identifier)
        if #available(iOS 14.0, *) {
            filterTableView.register(NewMensaNotificationTableViewCell.nib, forCellReuseIdentifier: NewMensaNotificationTableViewCell.identifier)
        } else {
            filterTableView.register(MensaNotificationTableViewCell.nib, forCellReuseIdentifier: MensaNotificationTableViewCell.identifier)
        }
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.layoutTableView()
        self.view.backgroundColor = UIColor.flatGray
    }
    func bindViewModel() {
        AppSessionManager.loadFoodAlarmTime()

        filterMensaViewModel.didUpdatefilterList.bind { [weak self] _ in
            if let `self` = self {
                self.realodTableView()
            }
        }
        filterMensaViewModel.onShowError = { [weak self] alert in
            DispatchQueue.main.async {
                self?.presentSingleButtonDialog(alert: alert)
            }
        }
        filterMensaViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {

                visible ? self.filterTableView.showingLoadingView() : self.filterTableView.hideLoadingView()
            }
        }
        filterMensaViewModel.didUpdateFoodAlarmStatus.bind { [weak self] _ in
            if let `self` = self {
                if self.filterMensaViewModel.didUpdateFoodAlarmStatus.value {
                    DispatchQueue.main.async {
                        self.updateTableView()
                    }
                } else {
                    self.reloadFoodAlramSection()
                }
            }
        }
        filterMensaViewModel.selectedAlramTime.bind {[weak self] _ in
            if let `self` = self {
                self.reloadFoodAlramSection()
            }
        }

    }

    func realodTableView() {
        DispatchQueue.main.async {
            self.filterTableView.reloadData()
        }
    }
    func reloadFoodAlramSection() {
        DispatchQueue.main.async {
            self.filterTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }
    @objc private func refershLoad() {
        // refresh the notices list from the server
        filterMensaViewModel.isFilterdCacheUpdated = false
        filterMensaViewModel.loadGetFilterList()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        actionAfterChangeCampus()
        saveContext()
        saveFoodAlramTime()
        if filterMensaViewModel.isFilterdCacheUpdated {
            self.delegate?.didUpdateNoticesData()
        }
        dismissView()
    }

    func actionAfterChangeCampus() {
        if filterMensaViewModel.mensaLocation != AppSessionManager.shared.selectedMensaLocation {
            AppSessionManager.shared.selectedMensaLocation = filterMensaViewModel.mensaLocation
            self.delegate?.didChangeLocationFilter()
            dismissView()
        }
    }
    func saveContext () {
        let context =  CoreDataStack.sharedInstance.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                self.delegate?.didUpdateNoticesFilter()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
            }
        }
    }

    // only needed for inline timepicker
    func saveFoodAlramTime() {
        if #available(iOS 14.0, *) {
            if filterMensaViewModel.isFoodAlarmEnabled {
                saveUserSelctedTime()
            }
        }
    }
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toNotificationTime = "NotificationTime"
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueIdentifiers.toNotificationTime,
            let destinationViewController = segue.destination as? NotificationTimeViewController {
            destinationViewController.selectedTime = filterMensaViewModel.selectedAlramTime.value
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
        if let priority =  filterForSectionIndex(indexPath.section) {
            switch priority {
            case .location:
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                cell.textLabel?.text = item?.filterName

                if item?.filterID == filterMensaViewModel.mensaLocation.locationKey {
                    cell.accessoryType = .checkmark
                }
            case .allergenList:
                let allergenCell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as?  FilterUISwitchTableViewCell
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                allergenCell?.cellTitle = item?.filterName
                allergenCell?.indexPath = indexPath
                allergenCell?.switchValue = item?.isSelected
                allergenCell?.mensaDelegate = self
                // the default cell selection is cancelled, to avoid conflicts touch interaction with the switch button
                allergenCell?.selectionStyle = .none
                return allergenCell ?? cell
            case .empty:
                return cell
            case .foodAlram:
                let items = filterMensaViewModel.filterList(for: priority)
                let item = items[safe: indexPath.row]
                if item?.filterID == "1" {
                    let alramCell = tableView.dequeueReusableCell(withIdentifier: FilterUISwitchTableViewCell.identifier, for: indexPath) as?  FilterUISwitchTableViewCell
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
        if #available(iOS 14.0, *) {
            let alramCell = tableView.dequeueReusableCell(withIdentifier: NewMensaNotificationTableViewCell.identifier, for: indexPath)
                as? NewMensaNotificationTableViewCell
            alramCell?.notificationSelectedTime = filterMensaViewModel.selectedAlramTime.value
            alramCell?.delegate = self
            return alramCell ?? cell
        } else {
            let alramCell = tableView.dequeueReusableCell(withIdentifier: MensaNotificationTableViewCell.identifier, for: indexPath) as?  MensaNotificationTableViewCell
            alramCell?.notificationSelectedTime = filterMensaViewModel.selectedAlramTime.value
            return alramCell ?? cell
        }
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
                DispatchQueue.main.async {
                    self.filterTableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
                }
                actionAfterChangeCampus()
            }
        } else if indexPath.section == 1, indexPath.row == 1, tableView.cellForRow(at: indexPath) is MensaNotificationTableViewCell {
            self.performSegue(withIdentifier: SegueIdentifiers.toNotificationTime, sender: self)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.section == 1 && indexPath.row == 1 && filterMensaViewModel.isFoodAlarmEnabled == false {
            return 0.0  // collapsed
        }
        // expanded with row height of parent
        //return tableView(filterTableView, heightForRowAt: indexPath)
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
                //filterMensaViewModel.filterList.value.noticesText[indexPath].isSelected = true
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
        filterMensaViewModel.selectedAlramTime.value = filterMensaViewModel.tmpSelectedAlramTime
        filterMensaViewModel.cancelNotification()
        filterMensaViewModel.scheduleNotification()
        filterMensaViewModel.tmpSelectedAlramTime = nil
    }

    func updateTableView() {
        // to initiate smooth animation
        DispatchQueue.main.async {
            self.filterTableView.beginUpdates()
            self.filterTableView.endUpdates()
        }

    }
    func selectedTime(time: Date) {
        self.filterMensaViewModel.selectedAlramTime.value = time
        self.updateTableView()
        self.filterMensaViewModel.cancelNotification()
        self.filterMensaViewModel.scheduleNotification()
    }
}
