// Copyright © 2015 Abhishek Banthia

import XCTest
@testable import Clocker

class ClockerUnitTests: XCTestCase {
    
    private let california = ["customLabel" : "Test",
                      "formattedAddress" : "San Francisco",
                      "place_id" : "TestIdentifier",
                      "timezoneID" : "America/Los_Angeles",
                      "nextUpdate" : "",
                      "latitude" : "37.7749295",
                      "longitude" : "-122.4194155"]
    
    private let mumbai = ["customLabel" : "Ghar",
                  "formattedAddress" : "Mumbai",
                  "place_id" : "ChIJwe1EZjDG5zsRaYxkjY_tpF0",
                  "timezoneID" : "Asia/Calcutta",
                  "nextUpdate" : "",
                  "latitude" : "19.0759837",
                  "longitude" : "72.8776559"]
    
    private let auckland = ["customLabel" : "Auckland",
                          "formattedAddress" : "New Zealand",
                          "place_id" : "ChIJh5Z3Fw4gLG0RM0dqdeIY1rE",
                          "timezoneID" : "Pacific/Auckland",
                          "nextUpdate" : "",
                          "latitude" : "-40.900557",
                          "longitude" : "174.885971"]
    
    private let florida = ["customLabel" : "Gainesville",
                            "formattedAddress" : "Florida",
                            "place_id" : "ChIJvypWkWV2wYgR0E7HW9MTLvc",
                            "timezoneID" : "America/New_York",
                            "nextUpdate" : "",
                            "latitude" : "27.664827",
                            "longitude" : "-81.5157535"]
    
    private let onlyTimezone: [String: Any] = ["timezoneID": "Africa/Algiers",
                                               "formattedAddress" : "Africa/Algiers",
                                               "place_id": "",
                                               "customLabel": "",
                                               "latitude": "",
                                               "longitude": ""]
    
    private let omaha: [String: Any] = ["timezoneID": "America/Chicago",
                                               "formattedAddress" : "Omaha",
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
        var currentFavourites = defaults.object(forKey: CLDefaultPreferenceKey) as! [Data]
        let oldCount = currentFavourites.count
        
        currentFavourites = currentFavourites.filter {
            let timezone = TimezoneData.customObject(from: $0)
            return timezone?.placeID != "TestIdentifier"
        }
        
        defaults.set(currentFavourites, forKey: CLDefaultPreferenceKey)
        
        XCTAssertTrue(currentFavourites.count == oldCount - 1)
    }

    // The below test might fail outside California or if DST is active!
    func testTimeDifference() {
        XCTAssertTrue(operations.timeDifference() == ", 12 hours 30 mins ahead", "Difference was unexpectedly: \(operations.timeDifference())")
        XCTAssertTrue(californiaOperations.timeDifference() == "", "Difference was unexpectedly: \(californiaOperations.timeDifference())")
        XCTAssertTrue(floridaOperations.timeDifference() == ", 3 hours ahead", "Difference was unexpectedly: \(floridaOperations.timeDifference())")
        XCTAssertTrue(aucklandOperations.timeDifference() == ", 19 hours ahead", "Difference was unexpectedly: \(aucklandOperations.timeDifference())")
        XCTAssertTrue(omahaOperations.timeDifference() == ", 2 hours ahead", "Difference was unexpectedly: \(omahaOperations.timeDifference())")
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
        
        XCTAssertNotNil(operations.date(with: 0, displayType: .menuDisplay))
    }
    
    func testTimezoneFormat() {
        let dataObject = TimezoneData(with: mumbai)
        UserDefaults.standard.set(NSNumber(value: 0), forKey: CLShowSecondsInMenubar) // Set to show seconds
        UserDefaults.standard.set(NSNumber(value: 0), forKey: CL24hourFormatSelectedKey) // Set to 12 hour format
        
        dataObject.setShouldOverrideGlobalTimeFormat(0)
        XCTAssertTrue(dataObject.timezoneFormat() == "h:mm:ss a")
        
        dataObject.setShouldOverrideGlobalTimeFormat(1)
        XCTAssertTrue(dataObject.timezoneFormat() == "HH:mm:ss")
        
        dataObject.setShouldOverrideGlobalTimeFormat(2)
        XCTAssertTrue(dataObject.timezoneFormat() == "h:mm:ss a")
        
        UserDefaults.standard.set(NSNumber(value: 1), forKey: CL24hourFormatSelectedKey) // Set to 24-Hour Format
        XCTAssertTrue(dataObject.timezoneFormat() == "HH:mm:ss")
        
        UserDefaults.standard.set(NSNumber(value: 1), forKey: CLShowSecondsInMenubar)
        
        dataObject.setShouldOverrideGlobalTimeFormat(0)
        XCTAssertTrue(dataObject.timezoneFormat() == "h:mm a")
        
        dataObject.setShouldOverrideGlobalTimeFormat(1)
        XCTAssertTrue(dataObject.timezoneFormat() == "HH:mm")
        
        dataObject.setShouldOverrideGlobalTimeFormat(2)
        XCTAssertTrue(dataObject.timezoneFormat() == "HH:mm")
        
        UserDefaults.standard.set(NSNumber(value: 0), forKey: CL24hourFormatSelectedKey)
        XCTAssertTrue(dataObject.timezoneFormat() == "h:mm a")
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
                                                                             format: dataObject.timezoneFormat(),
                                                                             timezoneIdentifier: dataObject.timezone(),
                                                                             locale: currentLocale)
            let convertedDate = dateFormatter.string(from: newDate)
            XCTAssertNotNil(convertedDate)
        }
    }

}
