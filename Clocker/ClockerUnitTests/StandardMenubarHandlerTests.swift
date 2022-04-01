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
    
    private func makeMockStore(with menubarMode: Int = 1) -> DataStore {
        // Wipe all timezones from UserDefaults
        guard let defaults = UserDefaults(suiteName: "com.abhishek.Clocker.StandardMenubarHandlerTests") else {
            XCTFail("User defaults couldn't be initialized")
            return DataStore.shared()
        }
        defaults.set(menubarMode, forKey: CLMenubarCompactMode)
        defaults.set(0, forKey: CLShowMeetingInMenubar)
        XCTAssertNotEqual(defaults, UserDefaults.standard)
        return DataStore(with: defaults)
    }
    
    private func saveObject(object: TimezoneData,
                            in store: DataStore,
                            at index: Int = -1) {
        var defaults = store.timezones()
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: object as Any)
        index == -1 ? defaults.append(encodedObject) : defaults.insert(encodedObject, at: index)
        store.setTimezones(defaults)
    }

    func testValidStandardMenubarHandler_returnMenubarTitle() {
        let store = makeMockStore()
        store.setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)

        let menubarTimezones = store.menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 1, "Count is \(String(describing: menubarTimezones?.count))")
    }

    func testUnfavouritedTimezone_returnEmptyMenubarTimezoneCount() {
        let store = makeMockStore()
        // Wipe all timezones from UserDefaults
        store.setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        saveObject(object: dataObject, in: store)

        let menubarTimezones = store.menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 0)
    }

    func testUnfavouritedTimezone_returnNilMenubarString() {
        let store = makeMockStore()
        // Wipe all timezones from UserDefaults
        store.setTimezones(nil)
        let menubarHandler = MenubarTitleProvider(with: store)
        let emptyMenubarString = menubarHandler.titleForMenubar()
        // Returns early because DataStore.menubarTimezones is nil
        XCTAssertNil(emptyMenubarString)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        saveObject(object: dataObject, in: store)

        let menubarString = menubarHandler.titleForMenubar() ?? ""

        // Test menubar string is absent
        XCTAssertTrue(menubarString.count == 0)
    }
    
    func testWithEmptyMenubarTimezones() {
        let store = makeMockStore()
        store.setTimezones(nil)
        let menubarHandler = MenubarTitleProvider(with: store)
        XCTAssertNil(menubarHandler.titleForMenubar())
    }
    
    func testWithStandardMenubarMode() {
        // Set mode to standard mode
        let store = makeMockStore(with: 0)
        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)
        
        let menubarHandler = MenubarTitleProvider(with: store)
        XCTAssertNil(menubarHandler.titleForMenubar())
    }
    
    func testProviderPassingAllConditions() {
        // Set mode to standard mode
        let store = makeMockStore()
        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)
        
        let menubarHandler = MenubarTitleProvider(with: store)
        XCTAssertNotNil(menubarHandler.titleForMenubar())
    }
}
