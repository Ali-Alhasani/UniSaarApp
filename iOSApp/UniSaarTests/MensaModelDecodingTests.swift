@testable import Uni_Saar
import XCTest

@MainActor
final class MensaModelDecodingTests: XCTestCase {
    private func decodeMenu(_ json: String) throws -> MensaMenuModel {
        try JSONDecoder.unisaarDefault.decode(MensaMenuModel.self, from: Data(json.utf8))
    }

    private func decodeDay(_ json: String) throws -> MensaDayModel {
        try JSONDecoder.unisaarDefault.decode(MensaDayModel.self, from: Data(json.utf8))
    }

    private func decodeMeal(_ json: String) throws -> MensaMealsModel {
        try JSONDecoder.unisaarDefault.decode(MensaMealsModel.self, from: Data(json.utf8))
    }

    private func decodeColor(_ json: String) throws -> MensaColorModel {
        try JSONDecoder.unisaarDefault.decode(MensaColorModel.self, from: Data(json.utf8))
    }

    // MARK: - MensaColorModel

    func testColorFullDecoding() throws {
        let color = try decodeColor(#"{"r":217,"g":38,"b":26}"#)
        XCTAssertEqual(color.red, 217)
        XCTAssertEqual(color.green, 38)
        XCTAssertEqual(color.blue, 26)
    }

    func testColorMissingChannelsDefaultZero() throws {
        let color = try decodeColor(#"{"r":100}"#)
        XCTAssertEqual(color.red, 100)
        XCTAssertEqual(color.green, 0)
        XCTAssertEqual(color.blue, 0)
    }

    func testColorNullChannelDefaultsZero() throws {
        let color = try decodeColor(#"{"r":null,"g":38,"b":26}"#)
        XCTAssertEqual(color.red, 0)
    }

    func testColorEmptyObjectAllZero() throws {
        let color = try decodeColor(#"{}"#)
        XCTAssertEqual(color, MensaColorModel.zero)
    }

    // MARK: - MensaMealsModel

    func testMealFullDecoding() throws {
        let json = #"{"id":42,"counterName":"Complete Meal","mealName":"Schnitzel","description":"crispy","openingHours":"11:30-14:15","color":{"r":200,"g":100,"b":50},"components":["Pommes","Salat"],"notices":["fi","la"]}"#
        let meal = try decodeMeal(json)
        XCTAssertEqual(meal.mealID, 42)
        XCTAssertEqual(meal.counterName, "Complete Meal")
        XCTAssertEqual(meal.mealDispalyName, "Schnitzel")
        XCTAssertEqual(meal.description, "crispy")
        XCTAssertEqual(meal.openiningHours, "11:30-14:15")
        XCTAssertEqual(meal.color.red, 200)
        XCTAssertEqual(meal.meals, ["Pommes", "Salat"])
        XCTAssertEqual(meal.notices, ["fi", "la"])
    }

    func testMealEmptyObjectAllDefaults() throws {
        let meal = try decodeMeal(#"{}"#)
        XCTAssertEqual(meal.mealID, 0)
        XCTAssertEqual(meal.counterName, "")
        XCTAssertEqual(meal.mealDispalyName, "")
        XCTAssertEqual(meal.description, "")
        XCTAssertEqual(meal.openiningHours, "")
        XCTAssertEqual(meal.color, MensaColorModel.zero)
        XCTAssertEqual(meal.meals, [])
        XCTAssertEqual(meal.notices, [])
    }

    func testMealIdAsNumericStringParsed() throws {
        let json = #"{"id":"12345","counterName":"","mealName":"","description":"","openingHours":"","color":{"r":0,"g":0,"b":0},"components":[],"notices":[]}"#
        let meal = try decodeMeal(json)
        XCTAssertEqual(meal.mealID, 12345)
    }

    func testMealComponentsNullDefaultsEmpty() throws {
        let meal = try decodeMeal(#"{"components":null}"#)
        XCTAssertEqual(meal.meals, [])
    }

    func testMealNoticesNullDefaultsEmpty() throws {
        let meal = try decodeMeal(#"{"notices":null}"#)
        XCTAssertEqual(meal.notices, [])
    }

    // MARK: - MensaDayModel

    func testDayFullDecoding() throws {
        let json = #"{"date":"2019-12-10","meals":[{"id":0,"counterName":"Complete Meal","mealName":"Schnitzel","description":"","openingHours":"11:30-14:15","color":{"r":217,"g":38,"b":26},"components":["Pommes"],"notices":[]}]}"#
        let day = try decodeDay(json)
        XCTAssertEqual(day.date, "2019-12-10")
        XCTAssertEqual(day.countersMeals.count, 1)
        XCTAssertEqual(day.countersMeals.first?.mealDispalyName, "Schnitzel")
        XCTAssertEqual(day.countersMeals.first?.meals, ["Pommes"])
    }

    func testDayMissingMealsDefaultsEmpty() throws {
        let day = try decodeDay(#"{"date":"2019-12-10"}"#)
        XCTAssertEqual(day.date, "2019-12-10")
        XCTAssertEqual(day.countersMeals, [])
    }

    func testDayNullMealsDefaultsEmpty() throws {
        let day = try decodeDay(#"{"date":"2019-12-10","meals":null}"#)
        XCTAssertEqual(day.countersMeals, [])
    }

    func testDayEmptyObjectAllDefaults() throws {
        let day = try decodeDay(#"{}"#)
        XCTAssertEqual(day.date, "")
        XCTAssertEqual(day.countersMeals, [])
    }

    // MARK: - MensaMenuModel

    func testMenuFullDecoding() throws {
        let json = #"{"days":[{"date":"today","meals":[]},{"date":"tomorrow","meals":[]}],"filtersLastChanged":"2024-01-01"}"#
        let menu = try decodeMenu(json)
        XCTAssertEqual(menu.daysMenus.count, 2)
        XCTAssertEqual(menu.daysMenus.first?.date, "today")
        XCTAssertEqual(menu.filtersLastChanged, "2024-01-01")
    }

    func testMenuMissingDaysDefaultsEmpty() throws {
        let menu = try decodeMenu(#"{"filtersLastChanged":"2024-01-01"}"#)
        XCTAssertEqual(menu.daysMenus, [])
    }

    func testMenuNullDaysDefaultsEmpty() throws {
        let menu = try decodeMenu(#"{"days":null,"filtersLastChanged":""}"#)
        XCTAssertEqual(menu.daysMenus, [])
    }

    func testMenuMissingFilterTimestampDefaultsEmpty() throws {
        let menu = try decodeMenu(#"{"days":[]}"#)
        XCTAssertEqual(menu.filtersLastChanged, "")
    }

    func testMenuEmptyObjectAllDefaults() throws {
        let menu = try decodeMenu(#"{}"#)
        XCTAssertEqual(menu.daysMenus, [])
        XCTAssertEqual(menu.filtersLastChanged, "")
    }
}
