//
//  DataClientCacheExtension.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/19/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import CoreData

@MainActor
extension DataClient {
    func saveInCoreDataWith(model: FilterLocationCellViewModel) {
        CacheClient.shared.saveInCoreDataWith(model: model)
    }

    func saveInCoreDataWith(model: FilterCategoriesCellViewModel) {
        CacheClient.shared.saveInCoreDataWith(model: model)
    }

    func saveInCoreDataWith(model: [MoreLinksModel]) {
        CacheClient.shared.saveInCoreDataWith(model: model)
    }

    func saveInCoreDataWith(model: [NumberModel]) {
        CacheClient.shared.saveInCoreDataWith(model: model)
    }

    func clearFilterCache() {
        CacheClient.shared.clearFilterCache()
    }

    func clearNewsCategoriesCache() {
        CacheClient.shared.clearNewsCategoriesCache()
    }

    func clearMoreLinksCache() {
        CacheClient.shared.clearMoreLinksCache()
    }

    func clearHelpfulNumbersCache() {
        CacheClient.shared.clearHelpfulNumbersCache()
    }
}
