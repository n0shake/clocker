// Copyright © 2015 Abhishek Banthia

import CoreModelKit
import XCTest

@testable import Clocker

class StandardMenubarHandlerTests: XCTestCase {
    private let mumbai = ["customLabel": "Ghar",
                          "formattedAddress": "Mumbai",
                          "place_id": "ChIJwe1EZjDG5zsRaYxkjY_tpF0",
                          "timezoneID": "Asia/Calcutta",
                          "nextUpdate": "",
                          "latitude": "19.0759837",
                          "longitude": "72.8776559"]

    func testValidStandardMenubarHandler_returnMenubarTitle() {
        // Wipe all timezones from UserDefaults
        DataStore.shared().setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        let operationsObject = TimezoneDataOperations(with: dataObject)
        operationsObject.saveObject()

        let menubarTimezones = DataStore.shared().menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 1)

        // Set standard menubar in Prefs
        UserDefaults.standard.set(1, forKey: CLMenubarCompactMode)

        let menubarHandler = MenubarHandler()
        let menubarString = menubarHandler.titleForMenubar() ?? ""

        // Test menubar string is present
        XCTAssertTrue(menubarString.count > 0)
        XCTAssertTrue(menubarString.contains("Ghar"))

        // Set default back to compact menubar
        UserDefaults.standard.set(0, forKey: CLMenubarCompactMode)
    }

    func testUnfavouritedTimezone_returnEmptyMenubarTimezoneCount() {
        // Wipe all timezones from UserDefaults
        DataStore.shared().setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        let operationsObject = TimezoneDataOperations(with: dataObject)
        operationsObject.saveObject()

        let menubarTimezones = DataStore.shared().menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 0)
    }

    func testUnfavouritedTimezone_returnNilMenubarString() {
        // Wipe all timezones from UserDefaults
        DataStore.shared().setTimezones(nil)
        let menubarHandler = MenubarHandler()
        let emptyMenubarString = menubarHandler.titleForMenubar()
        // Returns early because DataStore.menubarTimezones is nil
        XCTAssertNil(emptyMenubarString)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        let operationsObject = TimezoneDataOperations(with: dataObject)
        operationsObject.saveObject()

        let menubarString = menubarHandler.titleForMenubar() ?? ""

        // Test menubar string is absent
        XCTAssertTrue(menubarString.count == 0)
    }
}
