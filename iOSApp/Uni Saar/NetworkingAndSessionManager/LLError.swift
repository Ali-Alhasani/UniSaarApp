//
//  LLError.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

enum AppError: LocalizedError {
    case serverMessage(String)
    case networkFailure
    case decoding(DecodingFailure)

    enum DecodingFailure: Equatable {
        case emptyResponse
        case keyNotFound(String, String)
        case typeMismatch(String, String)
        case valueNotFound(String, String)
        case dataCorrupted(String)
    }

    var errorDescription: String? {
        switch self {
        case let .serverMessage(message): message
        case .networkFailure, .decoding: String(localized: "generalAPIError")
        }
    }
}

extension AppError.DecodingFailure {
    init(_ error: DecodingError) {
        switch error {
        case let .keyNotFound(key, ctx): self = .keyNotFound(key.stringValue, ctx.debugDescription)
        case let .typeMismatch(type, ctx): self = .typeMismatch(String(describing: type), ctx.debugDescription)
        case let .valueNotFound(type, ctx): self = .valueNotFound(String(describing: type), ctx.debugDescription)
        case let .dataCorrupted(ctx): self = .dataCorrupted(ctx.debugDescription)
        @unknown default: self = .dataCorrupted(error.localizedDescription)
        }
    }
}
