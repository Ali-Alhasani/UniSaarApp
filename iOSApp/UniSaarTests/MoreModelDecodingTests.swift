@testable import Uni_Saar
import XCTest

@MainActor
final class MoreModelDecodingTests: XCTestCase {
    private func decodeWire(_ json: String) throws -> MoreLinksModel.Wire {
        try JSONDecoder.unisaarDefault.decode(MoreLinksModel.Wire.self, from: Data(json.utf8))
    }

    private func decodeMore(_ json: String) throws -> MoreModel {
        try JSONDecoder.unisaarDefault.decode(MoreModel.self, from: Data(json.utf8))
    }

    // MARK: - MoreLinksModel.Wire

    func testWireFullDecoding() throws {
        let wire = try decodeWire(#"{"name":"Welcome Centre","link":"https://uni-saarland.de"}"#)
        XCTAssertEqual(wire.displayName, "Welcome Centre")
        XCTAssertEqual(wire.url, "https://uni-saarland.de")
    }

    func testWireMissingNameDefaultsEmpty() throws {
        let wire = try decodeWire(#"{"link":"https://uni-saarland.de"}"#)
        XCTAssertEqual(wire.displayName, "")
    }

    func testWireNullNameDefaultsEmpty() throws {
        let wire = try decodeWire(#"{"name":null,"link":"https://uni-saarland.de"}"#)
        XCTAssertEqual(wire.displayName, "")
    }

    func testWireWrongTypeNameDefaultsEmpty() throws {
        let wire = try decodeWire(#"{"name":42,"link":"https://uni-saarland.de"}"#)
        XCTAssertEqual(wire.displayName, "")
    }

    func testWireMissingLinkDefaultsEmpty() throws {
        let wire = try decodeWire(#"{"name":"Welcome Centre"}"#)
        XCTAssertEqual(wire.url, "")
    }

    func testWireEmptyObjectAllDefaults() throws {
        let wire = try decodeWire(#"{}"#)
        XCTAssertEqual(wire.displayName, "")
        XCTAssertEqual(wire.url, "")
    }

    // MARK: - MoreModel

    func testMoreModelFullDecoding() throws {
        let json = #"{"linksLastChanged":"2020-01-01","links":[{"name":"Welcome Centre","link":"https://a.com"},{"name":"AStA","link":"https://b.com"}]}"#
        let model = try decodeMore(json)
        XCTAssertEqual(model.linksLastChanged, "2020-01-01")
        XCTAssertEqual(model.links.count, 2)
        XCTAssertEqual(model.links[0].displayName, "Welcome Centre")
        XCTAssertEqual(model.links[0].url, "https://a.com")
        XCTAssertEqual(model.links[0].index, 0)
        XCTAssertEqual(model.links[1].displayName, "AStA")
        XCTAssertEqual(model.links[1].url, "https://b.com")
        XCTAssertEqual(model.links[1].index, 1)
    }

    func testMoreModelIndexAssignedByPosition() throws {
        let json = #"{"linksLastChanged":"","links":[{"name":"A","link":""},{"name":"B","link":""},{"name":"C","link":""}]}"#
        let model = try decodeMore(json)
        XCTAssertEqual(model.links[0].index, 0)
        XCTAssertEqual(model.links[1].index, 1)
        XCTAssertEqual(model.links[2].index, 2)
    }

    func testMoreModelMissingLinksDefaultsEmpty() throws {
        let model = try decodeMore(#"{"linksLastChanged":"2020-01-01"}"#)
        XCTAssertEqual(model.links, [])
    }

    func testMoreModelNullLinksDefaultsEmpty() throws {
        let model = try decodeMore(#"{"linksLastChanged":"2020-01-01","links":null}"#)
        XCTAssertEqual(model.links, [])
    }

    func testMoreModelEmptyObjectAllDefaults() throws {
        let model = try decodeMore(#"{}"#)
        XCTAssertEqual(model.linksLastChanged, "")
        XCTAssertEqual(model.links, [])
    }
}
