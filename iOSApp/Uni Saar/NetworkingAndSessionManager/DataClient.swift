//
//  DataClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

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
    @MainActor func getCampusMapCoordinates(cacheLastChanged: String) async throws -> CoordinatesCacheModel
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
    @MainActor func getCampusMapCoordinates(cacheLastChanged: String) async throws -> CoordinatesCacheModel {
        fatalError("getCampusMapCoordinates not implemented")
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
        let json = try await APIClient.sendRequest(requestURL: .newsFeed(pageNumber, numberOfItems, filter))
        return NewsFeedModel(json: json.dictionaryValue)
    }
    func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        let json = try await APIClient.sendRequest(requestURL: .events(month, year))
        return NewsFeedModel(json: json.dictionaryValue)
    }
    func getMensaMenu(locationKey: String) async throws -> MensaMenuModel {
        let json = try await APIClient.sendRequest(requestURL: .mensa(locationKey))
        return MensaMenuModel(json: json.dictionaryValue)
    }
    func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        let json = try await APIClient.sendRequest(requestURL: .mealDetails(mealId))
        return MealDetailsModel(json: json.dictionaryValue)
    }
    func getMensaInfo(locationKey: String) async throws -> MensaInfo {
        let json = try await APIClient.sendRequest(requestURL: .mensaInfo(locationKey))
        return MensaInfo(json: json.dictionaryValue)
    }
    func getMensaFilter() async throws -> MensaFilterModel {
        let json = try await APIClient.sendRequest(requestURL: .mensaFilters)
        return MensaFilterModel(json: json.dictionaryValue)
    }
    func getNewsCategories() async throws -> [NewsCategories] {
        let json = try await APIClient.sendRequest(requestURL: .newsFeedCategories)
        return json.arrayValue.map { NewsCategories(json: $0.dictionaryValue) }
    }
    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel {
        let json = try await APIClient.sendRequest(requestURL: .directorySearch(pageNumber, numberOfItems, query))
        return StaffModel(json: json.dictionaryValue)
    }
    func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel {
        let json = try await APIClient.sendRequest(requestURL: .staffDetails(staffId))
        return StaffDetailsModel(json: json.dictionaryValue)
    }
    func getMoreLinks(cacheLastChanged: String) async throws -> MoreModel {
        let json = try await APIClient.sendRequest(requestURL: .moreLinks(cacheLastChanged))
        return MoreModel(json: json.dictionaryValue)
    }
    func getDirectoryHelpfulNumbers(cacheLastChanged: String) async throws -> HelpfulNumbersModel {
        let json = try await APIClient.sendRequest(requestURL: .helpfulNumbers(cacheLastChanged))
        return HelpfulNumbersModel(json: json.dictionaryValue)
    }
    func getCampusMapCoordinates(cacheLastChanged: String) async throws -> CoordinatesCacheModel {
        let json = try await APIClient.sendRequest(requestURL: .mapCoordinate(cacheLastChanged))
        return CoordinatesCacheModel(json: json)
    }
}

// Used for testing only
final class MockAppDataClient: AppDataClient, @unchecked Sendable {
    var getNewsResult: Result<NewsFeedModel, Error>?
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel {
        switch getNewsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMensaResult: Result<MensaMenuModel, Error>?
    func getMensaMenu(locationKey: String) async throws -> MensaMenuModel {
        switch getMensaResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMealResult: Result<MealDetailsModel, Error>?
    func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        switch getMealResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getSearchDirectoryResult: Result<StaffModel, Error>?
    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel {
        switch getSearchDirectoryResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getHelpfulNumbersResult: Result<HelpfulNumbersModel, Error>?
    func getDirectoryHelpfulNumbers(cacheLastChanged: String) async throws -> HelpfulNumbersModel {
        switch getHelpfulNumbersResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMoreLinksResult: Result<MoreModel, Error>?
    func getMoreLinks(cacheLastChanged: String) async throws -> MoreModel {
        switch getMoreLinksResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getEventsResult: Result<NewsFeedModel, Error>?
    func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        switch getEventsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getStaffDetailsResult: Result<StaffDetailsModel, Error>?
    func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel {
        switch getStaffDetailsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getNewsCategoriesResult: Result<[NewsCategories], Error>?
    func getNewsCategories() async throws -> [NewsCategories] {
        switch getNewsCategoriesResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMensaFilterResult: Result<MensaFilterModel, Error>?
    func getMensaFilter() async throws -> MensaFilterModel {
        switch getMensaFilterResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
}
