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
    typealias GetNewsResult = CustomResult<NewsFeedModel, Error>
    typealias GetNewsCompletion = (_ result: GetNewsResult) -> Void
    func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int], completion: @escaping GetNewsCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.newsFeed(pageNumber, numberOfItems, filter), success: { (response) in
            if let responseData = response as? JSON {
                let news = NewsFeedModel(json: responseData.dictionaryValue)
                completion(.success(payload: news))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    typealias GetEventsResult = CustomResult<NewsFeedModel, Error>
    typealias GetEventsCompletion = (_ result: GetEventsResult) -> Void
    func getEvents(month: String, year: String, completion: @escaping GetNewsCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.events(month, year), success: { (response) in
            if let responseData = response as? JSON {
                let news = NewsFeedModel(json: responseData.dictionaryValue)
                completion(.success(payload: news))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    typealias GetMensaResult = CustomResult<MensaMenuModel, Error>
    typealias GetMensaCompletion = (_ result: GetMensaResult) -> Void
    func getMensaMenu(completion: @escaping GetMensaCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.mensa(AppSessionManager.shared.selectedMensaLocation.locationKey), success: { (response) in
            if let responseData = response as? JSON {
                let menu = MensaMenuModel(json: responseData.dictionaryValue)
                completion(.success(payload: menu))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    //to get meal deatils
    typealias GetMealResult = CustomResult<MealDetailsModel, Error>
    typealias GetMealCompletion = (_ result: GetMealResult) -> Void
    func getMealDetails(mealId: Int, completion: @escaping GetMealCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.mealDetails(mealId), success: { (response) in
            if let responseData = response as? JSON {
                let meal = MealDetailsModel(json: responseData.dictionaryValue)
                completion(.success(payload: meal))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    typealias GetMensaInfoResult = CustomResult<MensaInfo, Error>
    typealias GetMensaInfoCompletion = (_ result: GetMensaInfoResult) -> Void
    func getMensaInfo(completion: @escaping GetMensaInfoCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.mensaInfo(AppSessionManager.shared.selectedMensaLocation.locationKey), success: { (response) in
            if let responseData = response as? JSON {
                let mensaInfo = MensaInfo(json: responseData.dictionaryValue)
                completion(.success(payload: mensaInfo))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    //to get mensa filter
    typealias GetFilterResult = CustomResult<MensaFilterModel, Error>
    typealias GetFilterCompletion = (_ result: GetFilterResult) -> Void
    func getMensaFilter(completion: @escaping GetFilterCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.mensaFilters, success: { (response) in
            if let responseData = response as? JSON {
                let filterList = MensaFilterModel(json: responseData.dictionaryValue)
                completion(.success(payload: filterList))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

    //to get news categories
    typealias GetNewsCategoriesResult = CustomResult<[NewsCategories], Error>
    typealias GetNewsCategoriesCompletion = (_ result: GetNewsCategoriesResult) -> Void
    func getNewsCategories(completion: @escaping GetNewsCategoriesCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.newsFeedCategories, success: { (response) in
            if let responseData = response as? JSON {
                let filterList = responseData.arrayValue.map {NewsCategories(json: $0.dictionaryValue)}
                completion(.success(payload: filterList))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }
    //to get staff search resutls
    typealias GetSearchDirectoryResult = CustomResult<StaffModel, Error>
    typealias GetSearchDirectoryCompletion = (_ result: GetSearchDirectoryResult) -> Void
    func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String, completion: @escaping GetSearchDirectoryCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.directorySearch(pageNumber, numberOfItems, query), success: { (response) in
            if let responseData = response as? JSON {
                let searchResultList =  StaffModel(json: responseData.dictionaryValue)
                completion(.success(payload: searchResultList))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

    //to get staff details
    typealias GetStaffDetailsResult = CustomResult<StaffDetailsModel, Error>
    typealias GetStaffDetailsCompletion = (_ result: GetStaffDetailsResult) -> Void
    func getStaffDetails(staffId: Int, completion: @escaping GetStaffDetailsCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.staffDetails(staffId), success: { (response) in
            if let responseData = response as? JSON {
                let staff = StaffDetailsModel(json: responseData.dictionaryValue)
                completion(.success(payload: staff))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

    //to get more links
    typealias GetMoreLinksResult = CustomResult<MoreModel, Error>
    typealias GetMoreLinksCompletion = (_ result: GetMoreLinksResult) -> Void
    func getMoreLinks(completion: @escaping GetMoreLinksCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.moreLinks( AppSessionManager.shared.morelinksLastChanged), success: { (response) in
            if let responseData = response as? JSON {
                let moreLinks = MoreModel(json: responseData.dictionaryValue)
                completion(.success(payload: moreLinks))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

    //to get helpful Numbers
    typealias GetHelpfulNumbersResult = CustomResult<HelpfulNumbersModel, Error>
    typealias GetHelpfulNumbersCompletion = (_ result: GetHelpfulNumbersResult) -> Void
    func getDirectoryHelpfulNumbers(completion: @escaping GetHelpfulNumbersCompletion) {
        APIClient.sendRequest(requestURL: URLRouter.helpfulNumbers( AppSessionManager.shared.helpfulNumbersLastChanged), success: { (response) in
            if let responseData = response as? JSON {
                let helpfulNumbers =  HelpfulNumbersModel(json: responseData.dictionaryValue)
                completion(.success(payload: helpfulNumbers))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

    typealias GetMapCoordinatesResult = CustomResult<CoordinatesCacheModel, Error>
    typealias GetMapCoordinatesCompletion = (_ result: GetMapCoordinatesResult) -> Void
    func getCampusMapCoordinates(completion: @escaping GetMapCoordinatesCompletion, cacheLastChanged: String) {
        APIClient.sendRequest(requestURL: URLRouter.mapCoordinate(cacheLastChanged), success: { (response) in
            if let responseData = response as? JSON {
                let coordinatesCache = CoordinatesCacheModel(json: responseData)
                completion(.success(payload: coordinatesCache))
            }
        }, failure: { (error) in
            completion(.failure(error))
        })
    }

}
//this class is used for test purpose only 
final class MockAppDataClient: DataClient {
    var getNewsResult: DataClient.GetNewsResult?
    override func getNews(pageNumber: Int, numberOfItems: Int, filter: [Int], completion: @escaping (DataClient.GetNewsCompletion)) {
        completion(getNewsResult!)
    }
    var getMensaResult: DataClient.GetMensaResult?
    override func getMensaMenu(completion: @escaping (DataClient.GetMensaCompletion)) {
        completion(getMensaResult!)
    }

    var getMealResult: DataClient.GetMealResult?
    override func getMealDetails(mealId: Int, completion: @escaping (DataClient.GetMealCompletion)) {
        completion(getMealResult!)
    }
    var getSearchDirectoryResult: DataClient.GetSearchDirectoryResult?
    override func getSearchDirectory(pageNumber: Int, numberOfItems: Int, query: String, completion: @escaping DataClient.GetSearchDirectoryCompletion) {
        completion(getSearchDirectoryResult!)
    }

    var getHelpfulNumbersResult: DataClient.GetHelpfulNumbersResult?
    override func getDirectoryHelpfulNumbers(completion: @escaping DataClient.GetHelpfulNumbersCompletion) {
        completion(getHelpfulNumbersResult!)
    }

    var getMoreLinksResult: DataClient.GetMoreLinksResult?
    override func getMoreLinks(completion: @escaping DataClient.GetMoreLinksCompletion) {
        completion(getMoreLinksResult!)
    }
}
