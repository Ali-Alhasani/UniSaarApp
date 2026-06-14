@testable import Uni_Saar
import XCTest

private struct Payload: Decodable {
    let name: String
    let count: Int
    let tags: [String]
    let score: Int?
    let mealID: Int

    enum CodingKeys: String, CodingKey {
        case name, count, tags, score, mealID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.value(.name, default: "fallback")
        count = container.value(.count, default: -1)
        tags = container.value(.tags, default: [])
        score = container.optionalValue(.score)
        mealID = container.intValue(.mealID, default: -1)
    }
}

@MainActor
final class JSONCodingTests: XCTestCase {
    private func decode(_ json: String) throws -> Payload {
        try JSONDecoder.unisaarDefault.decode(Payload.self, from: Data(json.utf8))
    }

    // MARK: - value(_:default:)

    func testValuePresentCorrectType() throws {
        let payload = try decode(#"{"name":"hello"}"#)
        XCTAssertEqual(payload.name, "hello")
    }

    func testValueMissingKeyUsesDefault() throws {
        let payload = try decode(#"{}"#)
        XCTAssertEqual(payload.name, "fallback")
    }

    func testValueExplicitNullUsesDefault() throws {
        let payload = try decode(#"{"name":null}"#)
        XCTAssertEqual(payload.name, "fallback")
    }

    func testValueTypeMismatchUsesDefault() throws {
        let payload = try decode(#"{"count":"not-a-number"}"#)
        XCTAssertEqual(payload.count, -1)
    }

    func testValueArrayTypeMismatchUsesEmpty() throws {
        let payload = try decode(#"{"tags":"not-an-array"}"#)
        XCTAssertEqual(payload.tags, [])
    }

    // MARK: - optionalValue(_:)

    func testOptionalValuePresentReturnsValue() throws {
        let payload = try decode(#"{"score":42}"#)
        XCTAssertEqual(payload.score, 42)
    }

    func testOptionalValueMissingReturnsNil() throws {
        let payload = try decode(#"{}"#)
        XCTAssertNil(payload.score)
    }

    func testOptionalValueNullReturnsNil() throws {
        let payload = try decode(#"{"score":null}"#)
        XCTAssertNil(payload.score)
    }

    func testOptionalValueTypeMismatchReturnsNil() throws {
        let payload = try decode(#"{"score":"oops"}"#)
        XCTAssertNil(payload.score)
    }

    // MARK: - intValue(_:default:)

    func testIntValueJsonNumber() throws {
        let payload = try decode(#"{"mealID":42}"#)
        XCTAssertEqual(payload.mealID, 42)
    }

    func testIntValueNumericString() throws {
        let payload = try decode(#"{"mealID":"42"}"#)
        XCTAssertEqual(payload.mealID, 42)
    }

    func testIntValueLarge14DigitString() throws {
        let payload = try decode(#"{"mealID":"12345678901234"}"#)
        XCTAssertEqual(payload.mealID, 12_345_678_901_234)
    }

    func testIntValueNonNumericStringUsesDefault() throws {
        let payload = try decode(#"{"mealID":"abc"}"#)
        XCTAssertEqual(payload.mealID, -1)
    }

    func testIntValueMissingKeyUsesDefault() throws {
        let payload = try decode(#"{}"#)
        XCTAssertEqual(payload.mealID, -1)
    }

    func testIntValueNullUsesDefault() throws {
        let payload = try decode(#"{"mealID":null}"#)
        XCTAssertEqual(payload.mealID, -1)
    }
}
