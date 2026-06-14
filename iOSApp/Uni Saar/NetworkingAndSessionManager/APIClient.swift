//
//  APIClient.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Alamofire
import Foundation

enum APIClient {
    static func send<T: Decodable & Sendable>(
        _ request: URLRouter,
        as _: T.Type = T.self
    ) async throws -> T {
        let data = try await rawData(for: request)
        return try decode(T.self, from: data)
    }

    static func rawData(for request: URLRouter) async throws -> Data {
        log("→ \(request)", type: .note)
        let response = await AF.request(request)
            .cURLDescription { description in log(description, type: .note) }
            .validate()
            .serializingData()
            .response
        log("← \(response.response?.statusCode ?? 0) received at \(Date())", type: .note)
        switch response.result {
        case let .success(data):
            log("response body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")", type: .note)
            return data
        case let .failure(afError): throw mapTransportError(afError, body: response.data)
        }
    }

    private static func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        guard !data.isEmpty else { throw AppError.decoding(.emptyResponse) }
        do {
            return try JSONDecoder.unisaarDefault.decode(T.self, from: data)
        } catch {
            log("\(T.self) decode failed: \(error)", type: .error)
            if let decodingError = error as? DecodingError {
                throw AppError.decoding(.init(decodingError))
            }
            throw AppError.decoding(.dataCorrupted(error.localizedDescription))
        }
    }

    private static func mapTransportError(_ afError: AFError, body: Data?) -> Error {
        log("Transport error: \(afError)", type: .error)
        if let body, let message = String(data: body, encoding: .utf8),
           !message.isEmpty, !message.looksLikeHTML {
            return AppError.serverMessage(message)
        }
        return afError.isProtocolFailure ? AppError.networkFailure : afError.underlyingError ?? AppError.networkFailure
    }

    private static let logLevel: LogType = .none
    private static func log(_ message: @autoclosure () -> String, type: LogType) {
        #if DEBUG
            guard logLevel != .none, logLevel == .all || type == logLevel else { return }
            print("[APIClient]\(type.printCase()) \(message())")
        #endif
    }
}

// MARK: - Helpers

private extension String {
    var looksLikeHTML: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<")
    }
}

private extension AFError {
    var isProtocolFailure: Bool {
        isResponseSerializationError
            || isInvalidURLError
            || isParameterEncodingError
            || isResponseValidationError
    }
}
