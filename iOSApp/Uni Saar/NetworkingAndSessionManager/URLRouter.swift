//
//  URLRouter.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Alamofire
//All App API's
public enum URLRouter: URLRequestConvertible {
    enum Constants {
        static let baseURLPath = "http://unisaar-test.cs.uni-saarland.de:3000"
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
    var method: HTTPMethod {
        return .get
    }
    var language: String {
        return Locale.current.languageCode ?? "en"
    }
    var path: String {
        switch self {
        case .newsFeed:
            return "/news/mainScreen"
        case .mensa:
            return "/mensa/mainScreen"
        case .moreLinks:
            return "/more"
        case .directorySearch:
            return "directory/search"
        case .mealDetails:
            return "mensa/mealDetail"
        case .mensaInfo:
            return "mensa/info"
        case .mensaFilters:
            return "mensa/filters"
        case .newsFeedCategories:
            return "news/categories"
        case .staffDetails:
            return "directory/personDetails"
        case .events:
            return "events/mainScreen"
        case .helpfulNumbers:
            return "directory/helpfulNumbers"
        }
    }
    var parameters: [String: Any] {
        switch self {
        case .mensa(let location):
            return ["language": self.language, "location": location]
        case .mealDetails(let mealId):
            return ["meal": mealId, "language": self.language]
        case .mensaInfo(let location ):
            return ["location": location, "language": self.language]
        case .directorySearch(let pageNumber, let numberofItem, let query):
            return ["page": pageNumber, "pageSize": numberofItem, "query": query, "language": language]
        case .newsFeed(let pageNumber, let numberofItem, let filter):
            return ["page": pageNumber, "pageSize": numberofItem, "language": language, "negFilter": filter]
        case .mensaFilters:
            return ["language": language]
        case .newsFeedCategories:
            return ["language": language]
        case .staffDetails(let staffID):
            return ["pid": staffID, "language": language]
        case .events(let month, let year):
            return ["month": month, "year": year, "language": language]
        case .moreLinks(let lastUpdate):
            return ["language": language, "lastUpdated": lastUpdate]
        case .helpfulNumbers(let lastUpdate):
            return ["language": language, "lastUpdated": lastUpdate]
        }
    }
    public func asURLRequest() throws -> URLRequest {
        let url = try Constants.baseURLPath.asURL()
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.timeoutInterval = TimeInterval(10 * 1000)
        let urlEncoding = URLEncoding(arrayEncoding: .noBrackets)
        return try urlEncoding.encode(request, with: parameters)
    }
}
