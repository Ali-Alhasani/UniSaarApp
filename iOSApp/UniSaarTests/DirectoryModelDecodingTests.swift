@testable import Uni_Saar
import XCTest

@MainActor
final class DirectoryModelDecodingTests: XCTestCase {
    private func decodeStaffResult(_ json: String) throws -> StaffResultsModel {
        try JSONDecoder.unisaarDefault.decode(StaffResultsModel.self, from: Data(json.utf8))
    }

    private func decodeStaff(_ json: String) throws -> StaffModel {
        try JSONDecoder.unisaarDefault.decode(StaffModel.self, from: Data(json.utf8))
    }

    private func decodeNumber(_ json: String) throws -> NumberModel {
        try JSONDecoder.unisaarDefault.decode(NumberModel.self, from: Data(json.utf8))
    }

    private func decodeHelpfulNumbers(_ json: String) throws -> HelpfulNumbersModel {
        try JSONDecoder.unisaarDefault.decode(HelpfulNumbersModel.self, from: Data(json.utf8))
    }

    // MARK: - StaffResultsModel

    func testStaffResultFullDecoding() throws {
        let result = try decodeStaffResult(#"{"name":"Ali Baylan","title":"M.Sc","pid":9091}"#)
        XCTAssertEqual(result.fullName, "Ali Baylan")
        XCTAssertEqual(result.title, "M.Sc")
        XCTAssertEqual(result.staffID, 9091)
    }

    func testStaffResultMissingTitleDefaultsEmpty() throws {
        let result = try decodeStaffResult(#"{"name":"Ali Baylan","pid":9091}"#)
        XCTAssertEqual(result.title, "")
    }

    func testStaffResultNullNameDefaultsEmpty() throws {
        let result = try decodeStaffResult(#"{"name":null,"pid":9091}"#)
        XCTAssertEqual(result.fullName, "")
    }

    func testStaffResultMissingIdDefaultsZero() throws {
        let result = try decodeStaffResult(#"{"name":"Ali Baylan","title":""}"#)
        XCTAssertEqual(result.staffID, 0)
    }

    func testStaffResultEmptyObjectAllDefaults() throws {
        let result = try decodeStaffResult(#"{}"#)
        XCTAssertEqual(result.fullName, "")
        XCTAssertEqual(result.title, "")
        XCTAssertEqual(result.staffID, 0)
    }

    // MARK: - StaffModel

    func testStaffModelFullDecoding() throws {
        let json = #"{"results":[{"name":"Ali Baylan","title":"","pid":9091}],"itemCount":1,"hasNextPage":false}"#
        let model = try decodeStaff(json)
        XCTAssertEqual(model.staffResults.count, 1)
        XCTAssertEqual(model.staffResults.first?.fullName, "Ali Baylan")
        XCTAssertEqual(model.staffItemCount, 1)
        XCTAssertFalse(model.hasNextPage)
    }

    func testStaffModelHasNextPage() throws {
        let json = #"{"results":[],"itemCount":20,"hasNextPage":true}"#
        let model = try decodeStaff(json)
        XCTAssertTrue(model.hasNextPage)
        XCTAssertEqual(model.staffItemCount, 20)
    }

    func testStaffModelMissingResultsDefaultsEmpty() throws {
        let model = try decodeStaff(#"{"itemCount":0,"hasNextPage":false}"#)
        XCTAssertEqual(model.staffResults, [])
    }

    func testStaffModelNullResultsDefaultsEmpty() throws {
        let model = try decodeStaff(#"{"results":null,"itemCount":0,"hasNextPage":false}"#)
        XCTAssertEqual(model.staffResults, [])
    }

    func testStaffModelEmptyObjectAllDefaults() throws {
        let model = try decodeStaff(#"{}"#)
        XCTAssertEqual(model.staffResults, [])
        XCTAssertEqual(model.staffItemCount, 0)
        XCTAssertFalse(model.hasNextPage)
    }

    // MARK: - NumberModel

    func testNumberModelFullDecoding() throws {
        let json = #"{"name":"Student office","number":"0681 302-5491","link":"https://uni-saarland.de","mail":"info@uni.de"}"#
        let model = try decodeNumber(json)
        XCTAssertEqual(model.name, "Student office")
        XCTAssertEqual(model.number, "0681 302-5491")
        XCTAssertEqual(model.link, "https://uni-saarland.de")
        XCTAssertEqual(model.mail, "info@uni.de")
    }

    func testNumberModelAbsentFieldsAreNil() throws {
        let model = try decodeNumber(#"{}"#)
        XCTAssertNil(model.name)
        XCTAssertNil(model.number)
        XCTAssertNil(model.link)
        XCTAssertNil(model.mail)
    }

    func testNumberModelNullFieldsAreNil() throws {
        let json = #"{"name":null,"number":null,"link":null,"mail":null}"#
        let model = try decodeNumber(json)
        XCTAssertNil(model.name)
        XCTAssertNil(model.number)
        XCTAssertNil(model.link)
        XCTAssertNil(model.mail)
    }

    func testNumberModelPartialFieldsDecodeCorrectly() throws {
        let model = try decodeNumber(#"{"name":"AStA","number":"+49 681 302 2900"}"#)
        XCTAssertEqual(model.name, "AStA")
        XCTAssertEqual(model.number, "+49 681 302 2900")
        XCTAssertNil(model.link)
        XCTAssertNil(model.mail)
    }

    // MARK: - HelpfulNumbersModel

    func testHelpfulNumbersFullDecoding() throws {
        let json = #"{"numbersLastChanged":"2020-01-26","numbers":[{"name":"Student office","number":"0681 302-5491","link":"https://uni-saarland.de","mail":"info@uni.de"},{"name":"AStA","number":"+49 681 302 2900"}]}"#
        let model = try decodeHelpfulNumbers(json)
        XCTAssertEqual(model.numbersLastChanged, "2020-01-26")
        XCTAssertEqual(model.numbers.count, 2)
        XCTAssertEqual(model.numbers[0].name, "Student office")
        XCTAssertEqual(model.numbers[1].name, "AStA")
        XCTAssertNil(model.numbers[1].link)
    }

    func testHelpfulNumbersMissingNumbersDefaultsEmpty() throws {
        let model = try decodeHelpfulNumbers(#"{"numbersLastChanged":"2020-01-26"}"#)
        XCTAssertEqual(model.numbers, [])
    }

    func testHelpfulNumbersEmptyObjectAllDefaults() throws {
        let model = try decodeHelpfulNumbers(#"{}"#)
        XCTAssertEqual(model.numbersLastChanged, "")
        XCTAssertEqual(model.numbers, [])
    }
}
