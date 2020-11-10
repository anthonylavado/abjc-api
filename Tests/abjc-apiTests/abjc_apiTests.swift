import XCTest
@testable import abjc_api

final class abjc_apiTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(abjc_api().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
