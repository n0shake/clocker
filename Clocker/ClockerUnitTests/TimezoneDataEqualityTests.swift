// Copyright © 2015 Abhishek Banthia

import Foundation

@testable import Clocker
import XCTest

class TimezoneDataEqualityTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEqualityWhenTimezones() {
        let timezone1 = TimezoneData()
        timezone1.setLabel(CLEmptyString)
        timezone1.timezoneID = metaInfo.0.name
        timezone1.formattedAddress = TimeZone.system.identifer
        timezone1.selectionType = .timezone

        XCTAssert(timezone1 != nil)
    }
}
