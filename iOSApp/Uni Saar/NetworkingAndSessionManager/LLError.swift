//
//  LLError.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Alamofire
//our own custom class error handler, to show more friendly error networking/server messages
class LLError: NSObject, Error {
    var status: Bool
    var message: String
    init(status: Bool?, message: String) {
        self.status = status ?? true
        self.message = message
    }
}
extension LLError: LocalizedError {
    var errorDescription: String? { return message }
}

public enum MyError: Error {
    case customError
}

extension MyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .customError:
            //toDo: add this generalAPIError message later inside string file
            return NSLocalizedString("generalAPIError", comment: "My error")
        }
    }
}

//case invalidURL(url: URLConvertible)
//case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
//case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
//case responseValidationFailed(reason: ResponseValidationFailureReason)
//case responseSerializationFailed(reason: ResponseSerializationFailureReason)
extension AFError {
    public var myCustomErrorReasons: String {
        if case .parameterEncodingFailed(let reason) = self {
            switch reason {
            case .missingURL:
                return "parameter Encoding Failed, missing URL"
            case .jsonEncodingFailed:
                return "parameter Encoding Failed, json Encoding Failed"
            case .propertyListEncodingFailed:
                 return "parameter Encoding Failed, property List Encoding Failed"
            }
            //return "parameter Encoding Failed"
        } else if case .multipartEncodingFailed(let reason) = self {
             switch reason {
             case .bodyPartURLInvalid(let url):
                 return "multipartEncodingFailed, bodyPartURLInvalid , \(url)"
             case .bodyPartFilenameInvalid(let url):
                 return "multipartEncodingFailed, bodyPartFilenameInvalid , \(url)"
             case .bodyPartFileNotReachable(let url):
                 return "multipartEncodingFailed, bodyPartFileNotReachable , \(url)"
             case .bodyPartFileNotReachableWithError(let atURL, _):
                  return "multipartEncodingFailed, bodyPartFileNotReachableWithError , \(atURL)"
             case .bodyPartFileIsDirectory(let url):
                return "multipartEncodingFailed, bodyPartFileIsDirectory , \(url)"
             case .bodyPartFileSizeNotAvailable(let url):
                 return "multipartEncodingFailed, bodyPartFileSizeNotAvailable , \(url)"
             case .bodyPartFileSizeQueryFailedWithError(let forURL, _):
                 return "multipartEncodingFailed, bodyPartFileSizeQueryFailedWithError , \(forURL)"
             case .bodyPartInputStreamCreationFailed(let url):
                 return "multipartEncodingFailed, bodyPartInputStreamCreationFailed , \(url)"
             case .outputStreamCreationFailed(let url):
                 return "multipartEncodingFailed, outputStreamCreationFailed , \(url)"
             case .outputStreamFileAlreadyExists(let url):
                 return "multipartEncodingFailed, outputStreamFileAlreadyExists , \(url)"
             case .outputStreamURLInvalid(let url):
                 return "multipartEncodingFailed, outputStreamURLInvalid , \(url)"
             case .outputStreamWriteFailed:
                 return "multipartEncodingFailed, outputStreamWriteFailed"
             case .inputStreamReadFailed:
                return "multipartEncodingFailed, inputStreamReadFailed."
            }
            //return "multipart Encoding Failed"
        } else if case .responseSerializationFailed(let reason) = self {
            switch reason {
            case .inputDataNil:
                return "responseSerializationFailed, inputDataNil."
            case .inputDataNilOrZeroLength:
                 return "responseSerializationFailed, inputDataNilOrZeroLength."
            case .inputFileNil:
                return "responseSerializationFailed, inputFileNil."
            case .inputFileReadFailed(let atLocation):
                return "responseSerializationFailed, inputFileReadFailed. , \(atLocation)"
            case .stringSerializationFailed(let encoding):
                 return "responseSerializationFailed, stringSerializationFailed., \(encoding.description)"
            case .jsonSerializationFailed:
                  return "responseSerializationFailed, jsonSerializationFailed"
            case .propertyListSerializationFailed:
                  return "responseSerializationFailed, propertyListSerializationFailed"
            }
           // return "response Serialization Failed"
        } else if case .responseValidationFailed(let reason) = self {
            switch reason {
            case .dataFileNil:
                return "responseValidationFailed, dataFileNil."
            case .dataFileReadFailed(let atLocation):
                return "responseValidationFailed, dataFileReadFailed. , \(atLocation)"
            case .missingContentType(let acceptableContentTypes):
                 return "responseValidationFailed, missingContentType. , \(acceptableContentTypes)"
            case .unacceptableContentType(let acceptableContentTypes, _):
                 return "responseValidationFailed, unacceptableContentType. , \(acceptableContentTypes)"
            case .unacceptableStatusCode(let code):
                return "responseValidationFailed, unacceptableStatusCode. , \(code)"
            }
           // return "response Validation Failed"
        } else if case .invalidURL(let url)  = self {
           return "invalid URL , \(url)"
        }
        return "Unknown Error"
    }
}
