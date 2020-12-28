@testable import CoreLoggerKit
import XCTest

final class CoreLoggerKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CoreLoggerKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
