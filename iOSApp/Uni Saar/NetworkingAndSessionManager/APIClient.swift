//
//  APIClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class APIClient {
    class var sessionManager: Session {
        struct Static {
            static let instance = APIClient.getNewSessionManager()
        }
        return Static.instance
    }

    class func getNewSessionManager() -> Session {
        let configuration = URLSessionConfiguration.default
        return Session(configuration: configuration)
    }

    class func sendRequest(requestURL: URLRouter) async throws -> JSON {
        APIClient.printL("base url: \(requestURL)", type: .note)
        APIClient.printL("request fired", type: .note)
        let response = await APIClient.sessionManager.request(requestURL).validate().serializingData().response
        APIClient.printL("request: \(String(describing: response.request))", type: .note)
        APIClient.printL("Response Received : \(Date())", type: .note)
        switch response.result {
        case let .success(data):
            guard !data.isEmpty, let json = try? JSON(data: data) else {
                return JSON([:])
            }
            APIClient.printL("response: \(json)", type: .note)
            return json
        case let .failure(afError):
            APIClient.printL("Error while fetching data: \(afError)", type: .error)
            if let responseData = response.data,
               let jsonMessage = String(data: responseData, encoding: .utf8), !jsonMessage.isEmpty {
                throw AppError.serverMessage(jsonMessage)
            }
            if afError.isResponseSerializationError || afError.isInvalidURLError ||
                afError.isParameterEncodingError || afError.isResponseValidationError {
                throw AppError.networkFailure
            }
            throw afError.underlyingError ?? AppError.networkFailure
        }
    }

    class func printL(_ text: String, type: LogType) {
        let logType: LogType = .none
        if logType == .all || type == logType, type != .none {
            debugPrint("APIClient-\(type.printCase()) \(text)")
        }
    }
}
