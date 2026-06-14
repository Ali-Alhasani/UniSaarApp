//
//  DataClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import CoreData
import Foundation

protocol AppDataClient: AnyObject, Sendable {
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel
    func getEvents(month: String, year: String) async throws -> NewsFeedModel
    func getMensaMenu(locationKey: String) async throws -> MensaMenuModel
    func getMealDetails(mealId: Int) async throws -> MealDetailsModel
    func getMensaFilter() async throws -> MensaFilterModel
    func getNewsCategories() async throws -> [NewsCategories]
    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel
    func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel
    func getMoreLinks(cacheLastChanged: String) async throws -> MoreModel
    func getDirectoryHelpfulNumbers(cacheLastChanged: String) async throws -> HelpfulNumbersModel
    @MainActor func getCampusMapCoordinates(cacheLastChanged: String) async throws -> RemoteCampusCoordinates
    @MainActor func saveInCoreDataWith(model: FilterLocationCellViewModel)
    @MainActor func saveInCoreDataWith(model: FilterCategoriesCellViewModel)
    @MainActor func saveInCoreDataWith(model: [MoreLinksModel])
    @MainActor func saveInCoreDataWith(model: [NumberModel])
    @MainActor func clearFilterCache()
    @MainActor func clearNewsCategoriesCache()
    @MainActor func clearMoreLinksCache()
    @MainActor func clearHelpfulNumbersCache()
}

extension AppDataClient {
    @MainActor func getCampusMapCoordinates(cacheLastChanged: String) async throws -> RemoteCampusCoordinates {
        throw AppError.networkFailure
    }

    @MainActor func saveInCoreDataWith(model: FilterLocationCellViewModel) {}
    @MainActor func saveInCoreDataWith(model: FilterCategoriesCellViewModel) {}
    @MainActor func saveInCoreDataWith(model: [MoreLinksModel]) {}
    @MainActor func saveInCoreDataWith(model: [NumberModel]) {}
    @MainActor func clearFilterCache() {}
    @MainActor func clearNewsCategoriesCache() {}
    @MainActor func clearMoreLinksCache() {}
    @MainActor func clearHelpfulNumbersCache() {}
}

final class DataClient: AppDataClient {
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel {
        try await APIClient.send(.newsFeed(pageNumber, numberOfItems, filter))
    }

    func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        try await APIClient.send(.events(month, year))
    }

    func getMensaMenu(locationKey: String) async throws -> MensaMenuModel {
        try await APIClient.send(.mensa(locationKey))
    }

    func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        try await APIClient.send(.mealDetails(mealId))
    }

    func getMensaFilter() async throws -> MensaFilterModel {
        try await APIClient.send(.mensaFilters)
    }

    func getNewsCategories() async throws -> [NewsCategories] {
        try await APIClient.send(.newsFeedCategories)
    }

    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel {
        try await APIClient.send(.directorySearch(pageNumber, numberOfItems, query))
    }

    func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel {
        try await APIClient.send(.staffDetails(staffId))
    }

    func getMoreLinks(cacheLastChanged: String) async throws -> MoreModel {
        try await APIClient.send(.moreLinks(cacheLastChanged))
    }

    func getDirectoryHelpfulNumbers(cacheLastChanged: String) async throws -> HelpfulNumbersModel {
        try await APIClient.send(.helpfulNumbers(cacheLastChanged))
    }

    func getMensaInfo(locationKey: String) async throws -> MensaInfo {
        try await APIClient.send(.mensaInfo(locationKey))
    }

    @MainActor func getCampusMapCoordinates(cacheLastChanged: String) async throws -> RemoteCampusCoordinates {
        let raw = try await APIClient.rawData(for: .mapCoordinate(cacheLastChanged))
        guard !raw.isEmpty else { return .empty }
        let model = try JSONDecoder.unisaarDefault.decode(CampusCoordinatesModel.self, from: raw)
        return RemoteCampusCoordinates(model: model, rawData: raw)
    }
}

struct RemoteCampusCoordinates {
    let model: CampusCoordinatesModel
    let rawData: Data
    static let empty = RemoteCampusCoordinates(
        model: CampusCoordinatesModel(updateTime: "", mapInfo: []),
        rawData: Data()
    )
}

/// Used for testing only
final class MockAppDataClient: AppDataClient, @unchecked Sendable {
    var getNewsResult: Result<NewsFeedModel, Error>?
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel {
        switch getNewsResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getMensaResult: Result<MensaMenuModel, Error>?
    func getMensaMenu(locationKey: String) async throws -> MensaMenuModel {
        switch getMensaResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getMealResult: Result<MealDetailsModel, Error>?
    func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        switch getMealResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getSearchDirectoryResult: Result<StaffModel, Error>?
    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel {
        switch getSearchDirectoryResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getHelpfulNumbersResult: Result<HelpfulNumbersModel, Error>?
    func getDirectoryHelpfulNumbers(cacheLastChanged: String) async throws -> HelpfulNumbersModel {
        switch getHelpfulNumbersResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getMoreLinksResult: Result<MoreModel, Error>?
    func getMoreLinks(cacheLastChanged: String) async throws -> MoreModel {
        switch getMoreLinksResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getEventsResult: Result<NewsFeedModel, Error>?
    func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        switch getEventsResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getStaffDetailsResult: Result<StaffDetailsModel, Error>?
    func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel {
        switch getStaffDetailsResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getNewsCategoriesResult: Result<[NewsCategories], Error>?
    func getNewsCategories() async throws -> [NewsCategories] {
        switch getNewsCategoriesResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }

    var getMensaFilterResult: Result<MensaFilterModel, Error>?
    func getMensaFilter() async throws -> MensaFilterModel {
        switch getMensaFilterResult! {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }
}
