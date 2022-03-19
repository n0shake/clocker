// Copyright © 2015 Abhishek Banthia

import CoreModelKit
import Foundation
import XCTest

class TimezoneDataEqualityTests: XCTestCase {
    func testEqualityWhenTimezoneIdentifiersDiffer() {
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "SameLabel"

        let timezone2 = TimezoneData()
        timezone2.timezoneID = "Africa/Banjul"
        timezone2.formattedAddress = "SameLabel"

        XCTAssertFalse(timezone1 == timezone2) // Test ==
        XCTAssertNotEqual(timezone1, timezone2) // Test isEqual
    }

    func testEqualityWhenTimezonesLabelsDiffer() {
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "SameLabel"

        let timezone2 = TimezoneData()
        timezone2.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone2.formattedAddress = "DifferentLabel"

        XCTAssertFalse(timezone1 == timezone2)
        XCTAssertNotEqual(timezone1, timezone2)
    }

    func testEqualityWhenTimezonesPlaceIDsAreSame() {
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.placeID = "SamplePlaceID"
        timezone1.formattedAddress = "SameLabel"

        let timezone2 = TimezoneData()
        timezone2.placeID = "SamplePlaceID"
        timezone2.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone2.formattedAddress = "DifferentLabel"

        XCTAssertTrue(timezone1 == timezone2)
        XCTAssertEqual(timezone1, timezone2)
    }

    func testEqualityWhenTimezonesPlaceIDsDiffer() {
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.placeID = "SamplePlaceID1"
        timezone1.formattedAddress = "SameLabel"

        let timezone2 = TimezoneData()
        timezone2.placeID = "SamplePlaceID2"
        timezone2.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone2.formattedAddress = "DifferentLabel"

        XCTAssertFalse(timezone1 == timezone2)
        XCTAssertNotEqual(timezone1, timezone2)
    }
}
