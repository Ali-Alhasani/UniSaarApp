//
//  LegacyJSONShim.swift
//  UniSaarTests
//
//  Created by Ali Al-Hasani on 6/14/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

@testable import Uni_Saar
import Foundation
import SwiftyJSON

private func legacyDecode<T: Decodable>(_ dict: [String: Any], as _: T.Type, fallback: T) -> T {
    #if DEBUG
    assert(JSONSerialization.isValidJSONObject(dict),
           "LegacyJSONShim: \(T.self) dict contains a non-JSON value. Migrate this fixture in Stage 2.")
    #endif
    guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return fallback }
    return (try? JSONDecoder.unisaarDefault.decode(T.self, from: data)) ?? fallback
}

extension NewsFeedModel       { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension NewsModel           { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension StaffModel          { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension MoreModel           { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension HelpfulNumbersModel { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension MensaMenuModel      { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension MensaDayModel       { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension NumberModel         { init(json: [String: Any]) { self = legacyDecode(json, as: Self.self, fallback: .empty) } }
extension NumberModel         { init(json: JSON) { self = legacyDecode(json.dictionaryObject ?? [:], as: Self.self, fallback: .empty) } }
extension MoreLinksModel {
    init(json: [String: Any], index: Int) {
        let wire = legacyDecode(json, as: Wire.self, fallback: Wire(displayName: "", url: ""))
        self.init(displayName: wire.displayName, url: wire.url, index: index)
    }
    init(json: JSON, index: Int) {
        let wire = legacyDecode(json.dictionaryObject ?? [:], as: Wire.self, fallback: Wire(displayName: "", url: ""))
        self.init(displayName: wire.displayName, url: wire.url, index: index)
    }
}
