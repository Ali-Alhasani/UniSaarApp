@testable import Uni_Saar
import XCTest

@MainActor
final class NewsModelDecodingTests: XCTestCase {
    private func decodeNewsModel(_ json: String) throws -> NewsModel {
        try JSONDecoder.unisaarDefault.decode(NewsModel.self, from: Data(json.utf8))
    }

    private func decodeFeed(_ json: String) throws -> NewsFeedModel {
        try JSONDecoder.unisaarDefault.decode(NewsFeedModel.self, from: Data(json.utf8))
    }

    // MARK: - resolveDate()

    func testPublishedDateOnlyIsNotEvent() throws {
        let model = try decodeNewsModel(#"{"id":1,"title":"Test","publishedDate":"2024-01-01"}"#)
        XCTAssertFalse(model.isEvent)
        XCTAssertEqual(model.annoucementDate, "2024-01-01")
    }

    func testHappeningDateOnlyIsEvent() throws {
        let model = try decodeNewsModel(#"{"id":1,"title":"Test","happeningDate":"2024-06-15"}"#)
        XCTAssertTrue(model.isEvent)
        XCTAssertEqual(model.annoucementDate, "2024-06-15")
    }

    func testBothDatesPresentHappeningDateWins() throws {
        let model = try decodeNewsModel(
            #"{"id":1,"title":"Test","publishedDate":"2024-01-01","happeningDate":"2024-06-15"}"#
        )
        XCTAssertTrue(model.isEvent)
        XCTAssertEqual(model.annoucementDate, "2024-06-15")
    }

    func testHappeningDateNullFallsBackToPublishedDate() throws {
        let model = try decodeNewsModel(
            #"{"id":1,"title":"Test","happeningDate":null,"publishedDate":"2024-01-01"}"#
        )
        XCTAssertFalse(model.isEvent)
        XCTAssertEqual(model.annoucementDate, "2024-01-01")
    }

    func testNeitherDatePresentYieldsEmptyDate() throws {
        let model = try decodeNewsModel(#"{"id":1,"title":"Test"}"#)
        XCTAssertFalse(model.isEvent)
        XCTAssertEqual(model.annoucementDate, "")
    }

    // MARK: - NewsFeedModel leniency

    func testFullValidFeedDecodes() throws {
        let json = """
        {"itemCount":3,"categoriesLastChanged":"2024-01-01","hasNextPage":true,"items":[
            {"id":1,"title":"First","publishedDate":"2024-01-01"},
            {"id":2,"title":"Second","publishedDate":"2024-01-02"},
            {"id":3,"title":"Third","publishedDate":"2024-01-03"}
        ]}
        """
        let feed = try decodeFeed(json)
        XCTAssertEqual(feed.newsItemCount, 3)
        XCTAssertTrue(feed.hasNextPage)
        XCTAssertEqual(feed.newsList.count, 3)
    }

    func testFeedMissingHasNextPageDefaultsFalse() throws {
        let json = #"{"itemCount":1,"categoriesLastChanged":"","items":[{"id":1,"title":"T","publishedDate":"2024-01-01"}]}"#
        let feed = try decodeFeed(json)
        XCTAssertFalse(feed.hasNextPage)
    }

    func testFeedNullHasNextPageDefaultsFalse() throws {
        let json = #"{"itemCount":1,"categoriesLastChanged":"","hasNextPage":null,"items":[{"id":1,"title":"T","publishedDate":"2024-01-01"}]}"#
        let feed = try decodeFeed(json)
        XCTAssertFalse(feed.hasNextPage)
    }

    func testFeedStringItemCountTypeMismatchDefaultsZero() throws {
        let json = #"{"itemCount":"5","categoriesLastChanged":"","hasNextPage":false,"items":[]}"#
        let feed = try decodeFeed(json)
        XCTAssertEqual(feed.newsItemCount, 0)
    }

    func testFeedEmptyItemsDecodes() throws {
        let json = #"{"itemCount":0,"categoriesLastChanged":"","hasNextPage":false,"items":[]}"#
        let feed = try decodeFeed(json)
        XCTAssertEqual(feed.newsList.count, 0)
    }

    func testFeedEmptyObjectUsesAllDefaults() throws {
        let feed = try decodeFeed(#"{}"#)
        XCTAssertEqual(feed.newsItemCount, 0)
        XCTAssertEqual(feed.categoriesLastChanged, "")
        XCTAssertFalse(feed.hasNextPage)
        XCTAssertEqual(feed.newsList.count, 0)
    }

    // MARK: - NewsModel optional fields

    func testOptionalFieldsAbsentAreNil() throws {
        let model = try decodeNewsModel(#"{"id":1,"title":"Test","publishedDate":"2024-01-01"}"#)
        XCTAssertNil(model.subTitle)
        XCTAssertNil(model.imageURLString)
        XCTAssertNil(model.newslink)
    }

    func testOptionalFieldsPresentDecodeCorrectly() throws {
        let json = #"{"id":42,"title":"News","publishedDate":"2024-01-01","description":"A subtitle","link":"https://uni-saar.de","imageURL":"https://img.example.com/img.jpg"}"#
        let model = try decodeNewsModel(json)
        XCTAssertEqual(model.newsID, 42)
        XCTAssertEqual(model.subTitle, "A subtitle")
        XCTAssertEqual(model.newslink, "https://uni-saar.de")
        XCTAssertEqual(model.imageURLString, "https://img.example.com/img.jpg")
    }
}
