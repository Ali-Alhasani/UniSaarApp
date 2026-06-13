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

    var errorDescription: String? {
        switch self {
        case let .serverMessage(message): message
        case .networkFailure: String(localized: "generalAPIError")
        }
    }
}
