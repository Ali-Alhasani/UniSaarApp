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

class DataClient {
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel {
        let json = try await APIClient.sendRequest(requestURL: .newsFeed(pageNumber, numberOfItems, filter))
        return NewsFeedModel(json: json.dictionaryValue)
    }
    func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        let json = try await APIClient.sendRequest(requestURL: .events(month, year))
        return NewsFeedModel(json: json.dictionaryValue)
    }
    func getMensaMenu() async throws -> MensaMenuModel {
        let json = try await APIClient.sendRequest(requestURL: .mensa(AppSessionManager.shared.selectedMensaLocation.locationKey))
        return MensaMenuModel(json: json.dictionaryValue)
    }
    func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        let json = try await APIClient.sendRequest(requestURL: .mealDetails(mealId))
        return MealDetailsModel(json: json.dictionaryValue)
    }
    func getMensaInfo() async throws -> MensaInfo {
        let json = try await APIClient.sendRequest(requestURL: .mensaInfo(AppSessionManager.shared.selectedMensaLocation.locationKey))
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
    func getMoreLinks() async throws -> MoreModel {
        let json = try await APIClient.sendRequest(requestURL: .moreLinks(AppSessionManager.shared.morelinksLastChanged))
        return MoreModel(json: json.dictionaryValue)
    }
    func getDirectoryHelpfulNumbers() async throws -> HelpfulNumbersModel {
        let json = try await APIClient.sendRequest(requestURL: .helpfulNumbers(AppSessionManager.shared.helpfulNumbersLastChanged))
        return HelpfulNumbersModel(json: json.dictionaryValue)
    }
    func getCampusMapCoordinates(cacheLastChanged: String) async throws -> CoordinatesCacheModel {
        let json = try await APIClient.sendRequest(requestURL: .mapCoordinate(cacheLastChanged))
        return CoordinatesCacheModel(json: json)
    }
}

// Used for testing only
final class MockAppDataClient: DataClient {
    var getNewsResult: Result<NewsFeedModel, Error>?
    override func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int]) async throws -> NewsFeedModel {
        switch getNewsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMensaResult: Result<MensaMenuModel, Error>?
    override func getMensaMenu() async throws -> MensaMenuModel {
        switch getMensaResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMealResult: Result<MealDetailsModel, Error>?
    override func getMealDetails(mealId: Int) async throws -> MealDetailsModel {
        switch getMealResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getSearchDirectoryResult: Result<StaffModel, Error>?
    override func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String) async throws -> StaffModel {
        switch getSearchDirectoryResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getHelpfulNumbersResult: Result<HelpfulNumbersModel, Error>?
    override func getDirectoryHelpfulNumbers() async throws -> HelpfulNumbersModel {
        switch getHelpfulNumbersResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMoreLinksResult: Result<MoreModel, Error>?
    override func getMoreLinks() async throws -> MoreModel {
        switch getMoreLinksResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getEventsResult: Result<NewsFeedModel, Error>?
    override func getEvents(month: String, year: String) async throws -> NewsFeedModel {
        switch getEventsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getStaffDetailsResult: Result<StaffDetailsModel, Error>?
    override func getStaffDetails(staffId: Int) async throws -> StaffDetailsModel {
        switch getStaffDetailsResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getNewsCategoriesResult: Result<[NewsCategories], Error>?
    override func getNewsCategories() async throws -> [NewsCategories] {
        switch getNewsCategoriesResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
    var getMensaFilterResult: Result<MensaFilterModel, Error>?
    override func getMensaFilter() async throws -> MensaFilterModel {
        switch getMensaFilterResult! {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
}
