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
    class var sessionManager: Alamofire.SessionManager {
        struct Static {
            static let instance = APIClient.getNewSessionManager()
        }
        return Static.instance
    }
    class func getNewSessionManager() -> Alamofire.SessionManager {
        let configuration = URLSessionConfiguration.default
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        return sessionManager
    }
    class func sendRequest(requestURL: URLRouter, success: @escaping (_ response: Any?) -> Void, failure: @escaping (_ error: Error?) -> Void) {
        APIClient.printL("base url: \(requestURL)", type: .note)
        APIClient.sessionManager.request(requestURL).validate().responseJSON { response in
            APIClient.printL("request fired", type: .note)
            APIClient.printL("request: \(response.request!)", type: .note)
            APIClient.printL("Response Recieved : \(Date())", type: .note)
            APIClient.printL("response: \(String(describing: response.result.value))", type: .note)
            guard response.result.isSuccess,
                  let value = response.result.value else {
                APIClient.printL("Error while fetching data: \(String(describing: response.result.error))", type: .error)
                // check for custum server error message
                if let responseData = response.data, let jsonMessage = String(data: responseData, encoding: String.Encoding.utf8), jsonMessage != "" {
                    failure(LLError(status: false, message: jsonMessage))
                    return
                }
                //checking the error, to show a custom friendly error for the user
                if let overriddenError = response.result.error as? AFError {
                    if overriddenError.isResponseSerializationError || overriddenError.isInvalidURLError ||
                        overriddenError.isParameterEncodingError ||  overriddenError.isMultipartEncodingError ||   overriddenError.isResponseValidationError {
                        failure(MyError.customError)
                        return
                    }
                }
                failure(response.result.error)
                return
            }
            success(JSON(value))
        }
    }
    class func printL(_ text: String, type: LogType) {
        // change this to change what gets logged
        let logType: LogType = .all
        if(logType == .all || type == logType) && (type != .none) {
            debugPrint("APIClient-\(type.printCase()) \(text)")
        }
    }
}
