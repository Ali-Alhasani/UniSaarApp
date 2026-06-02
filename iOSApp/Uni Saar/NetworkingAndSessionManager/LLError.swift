//
//  LLError.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Alamofire
import Foundation

/// our own custom class error handler, to show more friendly error networking/server messages
final class LLError: NSObject, Error {
    let status: Bool
    let message: String
    init(status: Bool?, message: String) {
        self.status = status ?? true
        self.message = message
    }
}

extension LLError: LocalizedError {
    var errorDescription: String? {
        message
    }
}

public enum MyError: Error {
    case customError
}

extension MyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .customError:
            NSLocalizedString("generalAPIError", comment: "My error")
        }
    }
}

/// case invalidURL(url: URLConvertible)
/// case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
/// case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
/// case responseValidationFailed(reason: ResponseValidationFailureReason)
/// case responseSerializationFailed(reason: ResponseSerializationFailureReason)
public extension AFError {
    var myCustomErrorReasons: String {
        if case let .parameterEncodingFailed(reason) = self {
            switch reason {
            case .missingURL:
                return "parameter Encoding Failed, missing URL"
            case .jsonEncodingFailed:
                return "parameter Encoding Failed, json Encoding Failed"
            default:
                return "parameter Encoding Failed"
            }
            // return "parameter Encoding Failed"
        } else if case let .multipartEncodingFailed(reason) = self {
            switch reason {
            case let .bodyPartURLInvalid(url):
                return "multipartEncodingFailed, bodyPartURLInvalid , \(url)"
            case let .bodyPartFilenameInvalid(url):
                return "multipartEncodingFailed, bodyPartFilenameInvalid , \(url)"
            case let .bodyPartFileNotReachable(url):
                return "multipartEncodingFailed, bodyPartFileNotReachable , \(url)"
            case let .bodyPartFileNotReachableWithError(atURL, _):
                return "multipartEncodingFailed, bodyPartFileNotReachableWithError , \(atURL)"
            case let .bodyPartFileIsDirectory(url):
                return "multipartEncodingFailed, bodyPartFileIsDirectory , \(url)"
            case let .bodyPartFileSizeNotAvailable(url):
                return "multipartEncodingFailed, bodyPartFileSizeNotAvailable , \(url)"
            case let .bodyPartFileSizeQueryFailedWithError(forURL, _):
                return "multipartEncodingFailed, bodyPartFileSizeQueryFailedWithError , \(forURL)"
            case let .bodyPartInputStreamCreationFailed(url):
                return "multipartEncodingFailed, bodyPartInputStreamCreationFailed , \(url)"
            case let .outputStreamCreationFailed(url):
                return "multipartEncodingFailed, outputStreamCreationFailed , \(url)"
            case let .outputStreamFileAlreadyExists(url):
                return "multipartEncodingFailed, outputStreamFileAlreadyExists , \(url)"
            case let .outputStreamURLInvalid(url):
                return "multipartEncodingFailed, outputStreamURLInvalid , \(url)"
            case .outputStreamWriteFailed:
                return "multipartEncodingFailed, outputStreamWriteFailed"
            case .inputStreamReadFailed:
                return "multipartEncodingFailed, inputStreamReadFailed."
            }
            // return "multipart Encoding Failed"
        } else if case let .responseSerializationFailed(reason) = self {
            switch reason {
            case .inputDataNilOrZeroLength:
                return "responseSerializationFailed, inputDataNilOrZeroLength."
            case .inputFileNil:
                return "responseSerializationFailed, inputFileNil."
            case let .inputFileReadFailed(atLocation):
                return "responseSerializationFailed, inputFileReadFailed. , \(atLocation)"
            case let .stringSerializationFailed(encoding):
                return "responseSerializationFailed, stringSerializationFailed., \(encoding.description)"
            case .jsonSerializationFailed:
                return "responseSerializationFailed, jsonSerializationFailed"
            default:
                return "responseSerializationFailed"
            }
            // return "response Serialization Failed"
        } else if case let .responseValidationFailed(reason) = self {
            switch reason {
            case .dataFileNil:
                return "responseValidationFailed, dataFileNil."
            case let .dataFileReadFailed(atLocation):
                return "responseValidationFailed, dataFileReadFailed. , \(atLocation)"
            case let .missingContentType(acceptableContentTypes):
                return "responseValidationFailed, missingContentType. , \(acceptableContentTypes)"
            case let .unacceptableContentType(acceptableContentTypes, _):
                return "responseValidationFailed, unacceptableContentType. , \(acceptableContentTypes)"
            case let .unacceptableStatusCode(code):
                return "responseValidationFailed, unacceptableStatusCode. , \(code)"
            case let .customValidationFailed(error):
                return "responseValidationFailed, customValidationFailed. , \(error)"
            default:
                return "responseValidationFailed"
            }
            // return "response Validation Failed"
        } else if case let .invalidURL(url) = self {
            return "invalid URL , \(url)"
        }
        return "Unknown Error"
    }
}
