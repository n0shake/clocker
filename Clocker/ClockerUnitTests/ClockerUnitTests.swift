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

        let defaults = UserDefaults.standard
        let currentFavourites = (defaults.object(forKey: CLDefaultPreferenceKey) as? [Data]) ?? []
        let oldCount = currentFavourites.count

        let operationsObject = TimezoneDataOperations(with: timezoneData)
        operationsObject.saveObject()

        let newDefaults = UserDefaults.standard.object(forKey: CLDefaultPreferenceKey) as? [Data]

        XCTAssert(newDefaults != nil)
        XCTAssert(newDefaults?.count == oldCount + 1)
    }

    func testDeletingATimezone() {
        let defaults = UserDefaults.standard

        guard var currentFavourites = defaults.object(forKey: CLDefaultPreferenceKey) as? [Data] else {
            XCTFail("Default preferences aren't in the correct format")
            return
        }
        let oldCount = currentFavourites.count

        currentFavourites = currentFavourites.filter {
            let timezone = TimezoneData.customObject(from: $0)
            return timezone?.placeID != "TestIdentifier"
        }

        defaults.set(currentFavourites, forKey: CLDefaultPreferenceKey)

        XCTAssertTrue(currentFavourites.count == oldCount - 1)
    }

    // The below test might fail outside California or if DST is active!
    // CI is calibrated to be on LA timezone!
    func testTimeDifference() {
        XCTAssertTrue(operations.timeDifference() == ", 10h 30m ahead", "Difference was unexpectedly: \(operations.timeDifference())")
        XCTAssertTrue(californiaOperations.timeDifference() == ", 2h behind", "Difference was unexpectedly: \(californiaOperations.timeDifference())")
        XCTAssertTrue(floridaOperations.timeDifference() == ", an hour ahead", "Difference was unexpectedly: \(floridaOperations.timeDifference())")
        XCTAssertTrue(aucklandOperations.timeDifference() == ", 17h ahead", "Difference was unexpectedly: \(aucklandOperations.timeDifference())")
        XCTAssertTrue(omahaOperations.timeDifference() == "", "Difference was unexpectedly: \(omahaOperations.timeDifference())")
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
    }

    func testTimezoneFormatWithDefaultSetAs24HourFormat() {
        let dataObject = TimezoneData(with: california)
        UserDefaults.standard.set(NSNumber(value: 1), forKey: CLSelectedTimeZoneFormatKey) // Set to 24-Hour Format

        dataObject.setShouldOverrideGlobalTimeFormat(0)
        XCTAssertTrue(dataObject.timezoneFormat(DataStore.shared().timezoneFormat()) == "HH:mm")

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
    }

    func testFormattedLabel() {
        let dataObject = TimezoneData(with: mumbai)
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Ghar", "Incorrect custom label returned by model.")

        dataObject.customLabel = nil
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Mumbai", "Incorrect custom label returned by model.")

        dataObject.formattedAddress = nil
        XCTAssertTrue(dataObject.formattedTimezoneLabel() == "Asia", "Incorrect custom label returned by model.")
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
                                      options: .matchFirst) else {
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
}
