//
//  URLRouter.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Alamofire
import Foundation

/// All App API's
public enum URLRouter: URLRequestConvertible {
    enum Constants {
        static let baseURLPath = "http://localhost:3000"
    }

    case directorySearch(Int, Int, String)
    case mensa(String)
    case mealDetails(Int)
    case mensaInfo(String)
    case mensaFilters
    case moreLinks(String)
    case newsFeed(Int, Int, [Int])
    case newsFeedCategories
    case staffDetails(Int)
    case events(String, String)
    case helpfulNumbers(String)
    case mapCoordinate(String)
    case newsDetail(Int)
    case eventDetail(Int)
    var method: HTTPMethod {
        .get
    }

    var language: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    var path: String {
        switch self {
        case .newsFeed:
            "/news/mainScreen"
        case .mensa:
            "/mensa/mainScreen"
        case .moreLinks:
            "/more"
        case .directorySearch:
            "directory/search"
        case .mealDetails:
            "mensa/mealDetail"
        case .mensaInfo:
            "mensa/info"
        case .mensaFilters:
            "mensa/filters"
        case .newsFeedCategories:
            "news/categories"
        case .staffDetails:
            "directory/personDetails"
        case .events:
            "events/mainScreen"
        case .helpfulNumbers:
            "directory/helpfulNumbers"
        case .mapCoordinate:
            "map/"
        case .newsDetail:
            "news/details"
        case .eventDetail:
            "events/details"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .mensa(location):
            ["language": language, "location": location]
        case let .mealDetails(mealId):
            ["meal": mealId, "language": language]
        case let .mensaInfo(location):
            ["location": location, "language": language]
        case let .directorySearch(pageNumber, numberofItem, query):
            ["page": pageNumber, "pageSize": numberofItem, "query": query, "language": language]
        case let .newsFeed(pageNumber, numberofItem, filter):
            ["page": pageNumber, "pageSize": numberofItem, "language": language, "negFilter": filter]
        case .mensaFilters:
            ["language": language]
        case .newsFeedCategories:
            ["language": language]
        case let .staffDetails(staffID):
            ["pid": staffID, "language": language]
        case let .events(month, year):
            ["month": month, "year": year, "language": language]
        case let .moreLinks(lastUpdate):
            ["language": language, "lastUpdated": lastUpdate]
        case let .helpfulNumbers(lastUpdate):
            ["language": language, "lastUpdated": lastUpdate]
        case let .mapCoordinate(lastUpdate):
            ["lastUpdated": lastUpdate]
        case let .newsDetail(newsID):
            ["id": newsID]
        case let .eventDetail(eventID):
            ["id": eventID]
        }
    }

    public func asURLRequest() throws -> URLRequest {
        let base = try Constants.baseURLPath.asURL()
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        components.queryItems = parameters.flatMap { key, value -> [URLQueryItem] in
            if let ints = value as? [Int] {
                return ints.map { URLQueryItem(name: key, value: String($0)) }
            }
            return [URLQueryItem(name: key, value: "\(value)")]
        }
        var request = URLRequest(url: components.url ?? base)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 10000
        return request
    }
}
