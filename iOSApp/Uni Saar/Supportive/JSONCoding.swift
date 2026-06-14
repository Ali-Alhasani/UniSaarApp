//
//  JSONCoding.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 6/14/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

import Foundation

extension JSONDecoder {
    static let unisaarDefault: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .deferredToDate
        decoder.dataDecodingStrategy = .base64
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
}

extension JSONEncoder {
    static let unisaarDefault: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.outputFormatting = []
        return encoder
    }()
}

extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, default fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }

    func optionalValue<T: Decodable>(_ key: Key, as _: T.Type = T.self) -> T? {
        try? decodeIfPresent(T.self, forKey: key)
    }

    /// Decodes an Int the server may send as a JSON number or a numeric string.
    func intValue(_ key: Key, default fallback: Int = 0) -> Int {
        (try? decodeIfPresent(Int.self, forKey: key))
            ?? (try? decodeIfPresent(String.self, forKey: key)).flatMap { Int($0) }
            ?? fallback
    }
}
