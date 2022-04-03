// Copyright © 2015 Abhishek Banthia

import XCTest

@testable import Clocker

class DateFormatterManagerTests: XCTestCase {
    func testRegularDateFormatter() throws {
        let subject = DateFormatterManager.dateFormatter(with: .medium, for: "UTC")
        XCTAssertEqual(subject.dateStyle, .medium)
        XCTAssertEqual(subject.timeStyle, .medium)
        XCTAssertEqual(subject.locale.identifier, "en_US")
        XCTAssertEqual(subject.timeZone.identifier, "GMT")
    }

    func testDateFormatterWithFormat() throws {
        let subject = DateFormatterManager.dateFormatterWithFormat(with: .none, format: "hh:mm a", timezoneIdentifier: "Asia/Calcutta")
        XCTAssertEqual(subject.dateStyle, .none)
        XCTAssertEqual(subject.timeStyle, .none)
        XCTAssertEqual(subject.locale.identifier, "en_US")
        XCTAssertEqual(subject.timeZone.identifier, "Asia/Calcutta")
        XCTAssertEqual(subject.locale.identifier, "en_US")
        XCTAssertEqual(subject.dateFormat, "hh:mm a")
    }

    func testLocalizedDateFormatter() throws {
        let subject = DateFormatterManager.localizedFormatter(with: "hh:mm:ss", for: "America/Los_Angeles")
        XCTAssertEqual(subject.dateStyle, .none)
        XCTAssertEqual(subject.timeStyle, .none)
        XCTAssertEqual(subject.locale.identifier, Locale.autoupdatingCurrent.identifier)
        XCTAssertEqual(subject.timeZone.identifier, "America/Los_Angeles")
        XCTAssertEqual(subject.dateFormat, "hh:mm:ss")
    }
}
