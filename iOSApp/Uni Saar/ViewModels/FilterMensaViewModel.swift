//
//  FilterMensaViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/18/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData
class FilterMensaViewModel: ParentViewModel {
    // MARK: - Object Lifecycle
    let didUpdatefilterList: Bindable = Bindable(false)
    var isFilterdCacheUpdated: Bool = false

    enum Filter: Int, CaseIterable {
        case location, empty, allergenList
    }
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    var mensaLocation = AppSessionManager.shared.selectedMensaLocation
    var selectedNotices = [FilterElement]()
    //private var fetchedRC: NSFetchedResultsController<FilterNoticesListCache>!
    func loadGetFilterList() {
        showLoadingIndicator.value = true
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
