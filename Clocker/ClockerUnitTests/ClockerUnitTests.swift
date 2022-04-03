// Copyright © 2015 Abhishek Banthia

import CoreModelKit

@testable import Clocker
import XCTest

class ClockerUnitTests: XCTestCase {
    private let california = ["customLabel": "Test",
                              "formattedAddress": "San Francisco",
                              "place_id": "TestIdentifier",
                              "timezoneID": "America/Los_Angeles",
                              "nextUpdate": "",
                              "latitude": "37.7749295",
                              "longitude": "-122.4194155"]

    private let mumbai = ["customLabel": "Ghar",
                          "formattedAddress": "Mumbai",
                          "place_id": "ChIJwe1EZjDG5zsRaYxkjY_tpF0",
                          "timezoneID": "Asia/Calcutta",
                          "nextUpdate": "",
                          "latitude": "19.0759837",
                          "longitude": "72.8776559"]

    private let auckland = ["customLabel": "Auckland",
                            "formattedAddress": "New Zealand",
                            "place_id": "ChIJh5Z3Fw4gLG0RM0dqdeIY1rE",
                            "timezoneID": "Pacific/Auckland",
                            "nextUpdate": "",
                            "latitude": "-40.900557",
                            "longitude": "174.885971"]

    private let florida = ["customLabel": "Gainesville",
                           "formattedAddress": "Florida",
                           "place_id": "ChIJvypWkWV2wYgR0E7HW9MTLvc",
                           "timezoneID": "America/New_York",
                           "nextUpdate": "",
                           "latitude": "27.664827",
                           "longitude": "-81.5157535"]

    private let onlyTimezone: [String: Any] = ["timezoneID": "Africa/Algiers",
                                               "formattedAddress": "Africa/Algiers",
                                               "place_id": "",
                                               "customLabel": "",
                                               "latitude": "",
                                               "longitude": ""]

    private let omaha: [String: Any] = ["timezoneID": "America/Chicago",
                                        "formattedAddress": "Omaha",
                                        "place_id": "ChIJ7fwMtciNk4cRBLY3rk9NQkY",
                                        "customLabel": "",
                                        "latitude": "41.2565369",
                                        "longitude": "-95.9345034"]

    private var operations: TimezoneDataOperations {
        return TimezoneDataOperations(with: TimezoneData(with: mumbai))
    }

    private var californiaOperations: TimezoneDataOperations {
        return TimezoneDataOperations(with: TimezoneData(with: california))
    }

    private var floridaOperations: TimezoneDataOperations {
        return TimezoneDataOperations(with: TimezoneData(with: florida))
    }

    private var aucklandOperations: TimezoneDataOperations {
        return TimezoneDataOperations(with: TimezoneData(with: auckland))
    }

    private var omahaOperations: TimezoneDataOperations {
        return TimezoneDataOperations(with: TimezoneData(with: omaha))
    }

    func testOverridingSecondsComponent_shouldHideSeconds() {
        let dummyDefaults = UserDefaults.standard
        dummyDefaults.set(NSNumber(value: 4), forKey: CLSelectedTimeZoneFormatKey) // 4 is 12 hour with seconds

        let timezoneObjects = [TimezoneData(with: mumbai),
                               TimezoneData(with: auckland),
                               TimezoneData(with: california)]

        timezoneObjects.forEach {
            let operationsObject = TimezoneDataOperations(with: $0)
            let currentTime = operationsObject.time(with: 0)
            XCTAssert(currentTime.count == 8) // 8 includes 2 colons

            $0.setShouldOverrideGlobalTimeFormat(1)

            let newTime = operationsObject.time(with: 0)
            XCTAssert(newTime.count >= 7) // 5 includes colon
        }
    }

    func testAddingATimezoneToDefaults() {
        let timezoneData = TimezoneData(with: california)
        let currentFavourites = DataStore.shared().timezones()
        let oldCount = currentFavourites.count

        let operationsObject = TimezoneDataOperations(with: timezoneData)
        operationsObject.saveObject()

        let newDefaults = DataStore.shared().timezones()

        XCTAssert(newDefaults.isEmpty == false)
        XCTAssert(newDefaults.count == oldCount + 1)
    }

    func testDecoding() {
        let timezone1 = TimezoneData.customObject(from: nil)
        XCTAssertNotNil(timezone1)

        let data = Data()
        let timezone2 = TimezoneData.customObject(from: data)
        XCTAssertNil(timezone2)
    }

    func testDescription() {
        let timezoneData = TimezoneData(with: california)
        XCTAssertFalse(timezoneData.description.isEmpty)
        XCTAssertFalse(timezoneData.debugDescription.isEmpty)
    }

    func testHashing() {
        let timezoneData = TimezoneData(with: california)
        XCTAssert(timezoneData.hash != -1)

        timezoneData.placeID = nil
        timezoneData.timezoneID = nil
        XCTAssert(timezoneData.hash == -1)
    }

    func testBadInputDictionaryForInitialization() {
        let badInput: [String: Any] = ["customLabel": "",
                                       "latitude": "41.2565369",
                                       "longitude": "-95.9345034"]
        let badTimezoneData = TimezoneData(with: badInput)
        XCTAssertEqual(badTimezoneData.placeID, "Error")
        XCTAssertEqual(badTimezoneData.timezoneID, "Error")
        XCTAssertEqual(badTimezoneData.formattedAddress, "Error")
    }

    func testDeletingATimezone() {
        var currentFavourites = DataStore.shared().timezones()
        // Check if timezone with test identifier is present.
        let filteredCount = currentFavourites.filter {
            let timezone = TimezoneData.customObject(from: $0)
            return timezone?.placeID == "TestIdentifier"
        }

        // California is absent. Add it!
        if filteredCount.count == 0 {
            let timezoneData = TimezoneData(with: california)
            let operationsObject = TimezoneDataOperations(with: timezoneData)
            operationsObject.saveObject()
        }

        let oldCount = DataStore.shared().timezones().count

        currentFavourites = currentFavourites.filter {
            let timezone = TimezoneData.customObject(from: $0)
            return timezone?.placeID != "TestIdentifier"
        }

        DataStore.shared().setTimezones(currentFavourites)

        XCTAssertTrue(currentFavourites.count == oldCount - 1)
    }

    // The below test might fail outside California or if DST is active!
    // CI is calibrated to be on LA timezone!
    func testTimeDifference() {
        XCTAssertTrue(operations.timeDifference() == ", 9h 30m ahead", "Difference was unexpectedly: \(operations.timeDifference())")
        XCTAssertTrue(californiaOperations.timeDifference() == ", 3h behind", "Difference was unexpectedly: \(californiaOperations.timeDifference())")
        XCTAssertTrue(floridaOperations.timeDifference() == "", "Difference was unexpectedly: \(floridaOperations.timeDifference())")
        XCTAssertTrue(aucklandOperations.timeDifference() == ", 16h ahead", "Difference was unexpectedly: \(aucklandOperations.timeDifference())")
        XCTAssertTrue(omahaOperations.timeDifference() == ", an hour behind", "Difference was unexpectedly: \(omahaOperations.timeDifference())")
    }

    func testSunriseSunset() {
        let dataObject = TimezoneData(with: mumbai)
        let operations = TimezoneDataOperations(with: dataObject)

        XCTAssertNotNil(operations.formattedSunriseTime(with: 0))
        XCTAssertNotNil(dataObject.sunriseTime)
        XCTAssertNotNil(dataObject.sunriseTime)

        let timezoneObject = TimezoneData(with: onlyTimezone)
        timezoneObject.selectionType = .timezone
        let timezoneOperations = TimezoneDataOperations(with: timezoneObject)

        XCTAssertTrue(timezoneOperations.formattedSunriseTime(with: 0) == "")
        XCTAssertNil(timezoneObject.sunriseTime)
        XCTAssertNil(timezoneObject.sunsetTime)
    }

    func testDateWithSliderValue() {
        let dataObject = TimezoneData(with: mumbai)
        let operations = TimezoneDataOperations(with: dataObject)

        XCTAssertNotNil(operations.date(with: 0, displayType: .menu))
    }

    func testTimezoneFormat() {
        let dataObject = TimezoneData(with: mumbai)
        UserDefaults.standard.set(NSNumber(value: 0), forKey: CLSelectedTimeZoneFormatKey) // Set to 12 hour format

        dataObject.setShouldOverrideGlobalTimeFormat(0) // Respect Global Preference
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "h:mm a")

        dataObject.setShouldOverrideGlobalTimeFormat(1) // 12-Hour Format
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "h:mm a")

        dataObject.setShouldOverrideGlobalTimeFormat(2) // 24-Hour format
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm")

        // Skip 3 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(4) // 12-Hour with seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "h:mm:ss a")

        dataObject.setShouldOverrideGlobalTimeFormat(5) // 24-Hour format with seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm:ss")

        // Skip 6 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(7) // 12-hour with preceding zero and no seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm a")

        dataObject.setShouldOverrideGlobalTimeFormat(8) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm:ss a")

        // Skip 9 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(10) // 12-hour without am/pm and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm")

        dataObject.setShouldOverrideGlobalTimeFormat(11) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm:ss")

        // Wrong input
        dataObject.setShouldOverrideGlobalTimeFormat(0) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(88) == "h:mm a")
    }

    func testTimezoneFormatWithDefaultSetAs24HourFormat() {
        let dataObject = TimezoneData(with: california)
        UserDefaults.standard.set(NSNumber(value: 1), forKey: CLSelectedTimeZoneFormatKey) // Set to 24-Hour Format

        dataObject.setShouldOverrideGlobalTimeFormat(0)
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm",
                      "Unexpected format returned: \(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()))")

        dataObject.setShouldOverrideGlobalTimeFormat(1) // 12-Hour Format
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "h:mm a")

        dataObject.setShouldOverrideGlobalTimeFormat(2) // 24-Hour format
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm")

        // Skip 3 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(4) // 12-Hour with seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "h:mm:ss a")

        dataObject.setShouldOverrideGlobalTimeFormat(5) // 24-Hour format with seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm:ss")

        // Skip 6 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(7) // 12-hour with preceding zero and no seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm a")

        dataObject.setShouldOverrideGlobalTimeFormat(8) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm:ss a")

        // Skip 9 since it's a placeholder
        dataObject.setShouldOverrideGlobalTimeFormat(10) // 12-hour without am/pm and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm")

        dataObject.setShouldOverrideGlobalTimeFormat(11) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "hh:mm:ss")

        dataObject.setShouldOverrideGlobalTimeFormat(12) // 12-hour with preceding zero and seconds
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "epoch")
    }

    func testSecondsDisplayForOverridenTimezone() {
        let dataObject = TimezoneData(with: california)
        UserDefaults.standard.set(NSNumber(value: 1), forKey: CLSelectedTimeZoneFormatKey) // Set to 24-Hour Format

        // Test default behaviour
        let timezoneWithSecondsKeys = [4, 5, 8, 11]
        for timezoneKey in timezoneWithSecondsKeys {
            dataObject.setShouldOverrideGlobalTimeFormat(timezoneKey)
            XCTAssertTrue(dataObject.shouldShowSeconds(DataStore.shared().timezoneFormat()))
        }

        let timezoneWithoutSecondsKeys = [1, 2, 7, 10]
        for timezoneKey in timezoneWithoutSecondsKeys {
            dataObject.setShouldOverrideGlobalTimeFormat(timezoneKey)
            XCTAssertFalse(dataObject.shouldShowSeconds(DataStore.shared().timezoneFormat()))
        }

        // Test wrong override timezone key
        let wrongTimezoneKey = 88
        dataObject.setShouldOverrideGlobalTimeFormat(wrongTimezoneKey)
        XCTAssertFalse(dataObject.shouldShowSeconds(DataStore.shared().timezoneFormat()))

        // Test wrong global preference key
        dataObject.setShouldOverrideGlobalTimeFormat(0)
        XCTAssertFalse(dataObject.shouldShowSeconds(88))
    }

    func testTimezoneRetrieval() {
        let dataObject = TimezoneData(with: mumbai)
        let autoupdatingTimezone = TimeZone.autoupdatingCurrent.identifier
        XCTAssertEqual(dataObject.timezone(), "Asia/Calcutta")

        // Unlikely
        dataObject.timezoneID = nil
        XCTAssertEqual(dataObject.timezone(), autoupdatingTimezone)

        dataObject.isSystemTimezone = true
        XCTAssertEqual(dataObject.timezone(), autoupdatingTimezone)
    }

    func testFormattedLabel() {
        let dataObject = TimezoneData(with: mumbai)
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Ghar", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")

        dataObject.setLabel("")
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Mumbai", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")

        dataObject.formattedAddress = nil
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Asia", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")

        dataObject.setLabel("Jogeshwari")
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Jogeshwari", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")

        // Unlikely scenario
        dataObject.setLabel("")
        dataObject.timezoneID = "GMT"
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "GMT", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")

        // Another unlikely scenario
        dataObject.setLabel("")
        dataObject.timezoneID = nil
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Error", "Incorrect custom label returned by model \(dataObject.formattedTimezoneLabel())")
    }

    func testEquality() {
        let dataObject1 = TimezoneData(with: mumbai)
        let dataObject2 = TimezoneData(with: auckland)

        XCTAssertFalse(dataObject1 == dataObject2)
        XCTAssertFalse(dataObject1.isEqual(dataObject2))

        let dataObject3 = TimezoneData(with: mumbai)
        XCTAssertTrue(dataObject1 == dataObject3)
        XCTAssertTrue(dataObject1.isEqual(dataObject3))

        XCTAssertFalse(dataObject1.isEqual(nil))
    }

    func testWithAllLocales() {
        let dataObject1 = TimezoneData(with: mumbai)
        let operations = TimezoneDataOperations(with: dataObject1)

        for locale in Locale.availableIdentifiers {
            let currentLocale = Locale(identifier: locale)
            let localizedDate = operations.todaysDate(with: 0, locale: currentLocale)
            XCTAssertNotNil(localizedDate)
        }
    }

    func testTimeWithAllLocales() {
        let dataObject = TimezoneData(with: mumbai)

        let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)

        guard let newDate = cal?.date(byAdding: .minute,
                                      value: 0,
                                      to: Date(),
                                      options: .matchFirst)
        else {
            XCTFail("Unable to add dates!")
            return
        }

        for locale in Locale.availableIdentifiers {
            let currentLocale = Locale(identifier: locale)
            let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                             format: dataObject.timezoneFormat(DataStore.shared().timezoneFormat()),
                                                                             timezoneIdentifier: dataObject.timezone(),
                                                                             locale: currentLocale)
            let convertedDate = dateFormatter.string(from: newDate)
            XCTAssertNotNil(convertedDate)
        }
    }

    func testStringFiltering() {
        let stringWithComma = "Mumbai, Maharashtra"
        let stringWithoutComma = "Mumbai"
        let emptyString = ""

        XCTAssertEqual(stringWithComma.filteredName(), "Mumbai")
        XCTAssertEqual(stringWithoutComma.filteredName(), "Mumbai")
        XCTAssertEqual(emptyString.filteredName(), "")
    }

    func testToasty() {
        let view = NSView(frame: CGRect.zero)
        view.makeToast("Hello, this is a toast")
        XCTAssertEqual(view.subviews.first?.accessibilityIdentifier(), "ToastView") 
        let toastExpectation = expectation(description: "Toast View should hide after 1 second")
        let result = XCTWaiter.wait(for: [toastExpectation], timeout: 1.5) // Set 1.5 seconds here for a little leeway
        if result == XCTWaiter.Result.timedOut {
            XCTAssertTrue(view.subviews.isEmpty)
        }
    }

    func testPointingHandButton() {
        let sampleRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let pointingHandCursorButton = PointingHandCursorButton(frame: CGRect.zero)
        pointingHandCursorButton.draw(sampleRect)
        pointingHandCursorButton.resetCursorRects()
        XCTAssertEqual(pointingHandCursorButton.pointingHandCursor, NSCursor.pointingHand)
    }

    func testNoTimezoneView() {
        let sampleRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let subject = NoTimezoneView(frame: sampleRect)
        // Perform a layout to add subviews
        subject.layout()
        XCTAssertEqual(subject.subviews.count, 2) // Two textfields
        XCTAssertEqual(subject.subviews.first?.layer?.animationKeys(), ["notimezone.emoji"])
    }
}
