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
    func setupTableView() {
        filterTableView.register(FilterUISwitchTableViewCell.nib, forCellReuseIdentifier: FilterUISwitchTableViewCell.identifier)
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.layoutTableView()
        self.view.backgroundColor = UIColor.flatGray
    }
    func bindViewModel() {

        filterMensaViewModel.didUpdatefilterList.bind { [weak self] _ in
            if let `self` = self {
                self.filterTableView.reloadData()
            }
        }
        filterMensaViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        filterMensaViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.filterTableView.showingLoadingView() : self.filterTableView.hideLoadingView()
            }
        }
    }
    @objc private func refershLoad() {
        // refresh the notices list from the server
        filterMensaViewModel.isFilterdCacheUpdated = false
         filterMensaViewModel.loadGetFilterList()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        if filterMensaViewModel.mensaLocation != AppSessionManager.shared.selectedMensaLocation {
            AppSessionManager.shared.selectedMensaLocation = filterMensaViewModel.mensaLocation
            self.delegate?.didChangeLocationFilter()
        }
        saveContext()
        if filterMensaViewModel.isFilterdCacheUpdated {
            self.delegate?.didUpdateNoticesData()
        }
        dismissView()
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
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
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
                allergenCell?.indexPath = indexPath.row
                allergenCell?.switchValue = item?.isSelected
                allergenCell?.mensaDelegate = self
                // the default cell selection is cancelled, to avoid conflicts touch interaction with the switch button
                allergenCell?.selectionStyle = .none
                return allergenCell ?? cell
            case .empty:
                return cell
            }
        }
        return cell
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
            }
        }
    }
}
extension FilterMensaViewController: SingleButtonDialogPresenter { }
extension FilterMensaViewController: MensaFilterCellDelegate {
    func didSwitchOnFilter(indexPath: Int?) {
        if let indexPath = indexPath {
            //filterMensaViewModel.filterList.value.noticesText[indexPath].isSelected = true
            let noticeEntry = Cache.shared.fetchedResultsController.object(at: IndexPath(item: indexPath, section: 0))
            let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: noticeEntry.objectID) as? FilterNoticesListCache
            childEntry?.isSelected = true
        }
    }

    func didSwitchOffFilter(indexPath: Int?) {
        if let indexPath = indexPath {
            let noticeEntry = Cache.shared.fetchedResultsController.object(at: IndexPath(item: indexPath, section: 0))
            let childEntry = CoreDataStack.sharedInstance.persistentContainer.viewContext.object(with: noticeEntry.objectID) as? FilterNoticesListCache
            childEntry?.isSelected = false
        }
    }
}
