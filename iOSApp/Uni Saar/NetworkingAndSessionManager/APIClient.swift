//
//  APIClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Alamofire
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
        let sessionManager = Session(configuration: configuration)
        return sessionManager
    }
    class func sendRequest(requestURL: URLRouter, success: @escaping (_ response: Any?) -> Void, failure: @escaping (_ error: Error?) -> Void) {
        APIClient.printL("base url: \(requestURL)", type: .note)
        APIClient.sessionManager.request(requestURL).validate().responseJSON { response in
            APIClient.printL("request fired", type: .note)
            APIClient.printL("request: \(String(describing: response.request))", type: .note)
            APIClient.printL("Response Recieved : \(Date())", type: .note)
            switch response.result {
            case .success(let value):
                APIClient.printL("response: \(value)", type: .note)
                success(JSON(value))
            case .failure(let afError):
                APIClient.printL("Error while fetching data: \(afError)", type: .error)
                if let responseData = response.data,
                   let jsonMessage = String(data: responseData, encoding: .utf8), !jsonMessage.isEmpty {
                    failure(LLError(status: false, message: jsonMessage))
                    return
                }
                if afError.isResponseSerializationError || afError.isInvalidURLError ||
                    afError.isParameterEncodingError || afError.isResponseValidationError {
                    failure(MyError.customError)
                    return
                }
                failure(afError)
            }
        }
    }
    class func printL(_ text: String, type: LogType) {
        // change this to change what gets logged
        let logType: LogType = .none
        if(logType == .all || type == logType) && (type != .none) {
            debugPrint("APIClient-\(type.printCase()) \(text)")
        }
    }
}
