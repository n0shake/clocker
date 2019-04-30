// Copyright © 2015 Abhishek Banthia

import XCTest

class PreferencesTest: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append(CLUITestingLaunchArgument)
        app.launch()
        if app.tables["FloatingTableView"].exists {
            app.tapMenubarIcon()
            app.buttons["FloatingPin"].click()
        }
    }

    func testRemovingButtonVisibility() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        let predicate = NSPredicate(format: "identifier BEGINSWITH 'DeleteTimezone'", "")
        let beforeTimezoneSelected = app.windows["Clocker"].checkBoxes.matching(predicate).firstMatch

        XCTAssertFalse(beforeTimezoneSelected.isEnabled)

        if app.tables["TimezoneTableView"].tableRows.count <= 0 {
            XCTFail("There are no timezones.")
        }

        app.windows["Clocker"].tables["TimezoneTableView"].tableRows.firstMatch.click()

        XCTAssertTrue(app.checkBoxes["DeleteTimezone"].isEnabled)
    }

    func testAddingATimezone() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        app.sheets.radioGroups.radioButtons["Search by Timezone(s)"].click()

        addAPlace(place: "UTC", to: app)

        let matchPredicate = NSPredicate(format: "value == %@", "UTC")
        let matchingFields = app.windows["Clocker"].textFields.matching(matchPredicate)
        XCTAssertTrue(matchingFields.count > 0, "Matching Fields count was zero")

        deleteAPlace(place: "UTC", for: app)
    }
    
    func testEditingLabel() {
        
        let placeToAdd = "Auckland"
        
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)
        
        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }
        
        addAPlace(place: placeToAdd, to: app)
        
        let matchPredicate = NSPredicate(format: "value == %@", placeToAdd)
        let matchingFields = app.windows["Clocker"].textFields.matching(matchPredicate)
        XCTAssertTrue(matchingFields.count > 1, "Matching Fields count was zero")
        
        matchingFields.element(boundBy: 1).doubleClick()
        matchingFields.element(boundBy: 1).typeText("NZ")
        app.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
        app.tapMenubarIcon()
        
        let labelPredicate = NSPredicate(format: "label == %@", "NZ")
        let cells = app.tables["mainTableView"].cells.matching(labelPredicate)
        XCTAssert(cells.count > 0)
        
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)
        deleteAPlace(place: placeToAdd, for: app)
        
    }

    func testSortingByTimezoneDifference() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        deleteAllPlaces(app: app)

        addAPlace(place: "New Zealand", to: app)
        addAPlace(place: "San Francisco", to: app)
        addAPlace(place: "Florida", to: app, shouldSleep: false) // Last elements don't need to sleep

        app.windows["Clocker"].checkBoxes["SortButton"].click()

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Time Difference"].exists)

        app.windows["Clocker"].checkBoxes["Sort by Time Difference"].click()

        var actualLabels: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                actualLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualLabels, ["New Zealand", "Florida", "San Francisco"])

        app.windows["Clocker"].checkBoxes["Sort by Time Difference"].click()

        var actualReversedLabels: [String] = []
        let newReversedQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newReversedQuery.count {
            if let currentValue = newReversedQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                actualReversedLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualReversedLabels, ["San Francisco", "Florida", "New Zealand"])

        addAPlace(place: "Omaha", to: app)
        addAPlace(place: "Mumbai", to: app)
    }
    
    func testSortingByTimezoneName() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)
        app.windows["Clocker"].checkBoxes["SortButton"].click()

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Time Difference"].exists)
        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Label"].exists)
        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Name"].exists)

        var formattedAddress: [String] = []

        let formattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< formattedAddressQuery.count {
            if let currentValue = formattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                formattedAddress.append(currentValue)
            }
        }

        formattedAddress.sort()

        if let value = app.windows["Clocker"].checkBoxes["Sort by Name"].value as? Int, value == 0 {
            app.windows["Clocker"].checkBoxes["Sort by Name"].click()
        }

        var newformattedAddress: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                newformattedAddress.append(currentValue)
            }
        }

        XCTAssertEqual(newformattedAddress, formattedAddress)

        app.windows["Clocker"].checkBoxes["SortButton"].click()

        XCTAssertFalse(app.windows["Clocker"].checkBoxes["Sort by Time Difference"].exists)
        XCTAssertFalse(app.windows["Clocker"].checkBoxes["Sort by Label"].exists)
        XCTAssertFalse(app.windows["Clocker"].checkBoxes["Sort by Name"].exists)
    }

    func testSortingByCustomLabel() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        addAPlace(place: "Aurangabad", to: app)
        addAPlace(place: "Zimbabwe", to: app)
        addAPlace(place: "Portland", to: app, shouldSleep: false)

        app.windows["Clocker"].checkBoxes["SortButton"].click()

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Label"].exists)

        var expectedLabels: [String] = []

        let formattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< formattedAddressQuery.count {
            if let currentValue = formattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 1 {
                expectedLabels.append(currentValue)
            }
        }

        expectedLabels.sort()

        if let value = app.windows["Clocker"].checkBoxes["Sort by Label"].value as? Int, value == 0 {
            app.windows["Clocker"].checkBoxes["Sort by Label"].click()
        }

        var actualLabels: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 1 {
                actualLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualLabels, expectedLabels)

        deleteAPlace(place: "Aurangabad", for: app)
        deleteAPlace(place: "Zimbabwe", for: app)
        deleteAPlace(place: "Portland", for: app, shouldSleep: false)
    }

    func testSearchingWithMisspelledName() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)
        
        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }
        
        let searchField = app.searchFields["AvailableSearchField"]
        searchField.reset(text: "StuJjlqh7AcJFnBuOdgNa2dQ4WrIajP9Mo8R83FV7fIZ3B8zE2n")
        
        sleep(1)
        
        let maxCharacterCountPredicate = NSPredicate(format: "value like %@", "Only 50 characters allowed!")
        let currentSheets = app.sheets.firstMatch.staticTexts
        let maxCharacterQuery = currentSheets.matching(maxCharacterCountPredicate)
        
        XCTAssertTrue(maxCharacterQuery.count > 0)
        
        addAPlace(place: "asdakjhdasdahsdasd", to: app, shouldSleep: false)
        XCTAssertTrue(app.sheets.staticTexts["Please select a timezone!"].exists)

        let informativeLabelPredicate = NSPredicate(format: "placeholderValue like %@", "No results! 😔 Try entering the exact name.")
        let sheets = app.sheets.firstMatch.staticTexts
        let query = sheets.matching(informativeLabelPredicate)

        XCTAssertTrue(query.count > 0)

        addAPlace(place: "Cambodia", to: app)

        let newInformativeLabelPredicate = NSPredicate(format: "placeholderValue like %@", "No results! 😔 Try entering the exact name.")
        let newSheets = app.sheets.firstMatch.staticTexts
        let newQuery = newSheets.matching(newInformativeLabelPredicate)
        XCTAssertTrue(newQuery.count == 0, "New Query returned \(newQuery.count)")
        XCTAssertFalse(app.sheets.staticTexts["Please select a timezone!"].exists)

        deleteAPlace(place: "Cambodia", for: app, shouldSleep: false)
    }

    func testPlaceholderStrings() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        app.sheets.radioGroups.radioButtons["Search by Timezone(s)"].click()
        let expectedPlaceholder = "Enter a timezone name"
        let currentPlaceholder = app.sheets.searchFields["AvailableSearchField"]
        XCTAssertTrue(currentPlaceholder.exists, "Search Field doesn't exist")
        XCTAssertEqual(currentPlaceholder.placeholderValue!, expectedPlaceholder)

        let newPlaceholderValue = "Enter a city, state or country name"
        app.sheets.radioGroups.radioButtons["Search By City"].click()
        let newPlaceholder = app.sheets.searchFields["AvailableSearchField"]
        XCTAssertTrue(newPlaceholder.exists, "Search Field doesn't exist")
        XCTAssertEqual(newPlaceholder.placeholderValue!, newPlaceholderValue)
    }
    
    func testNoTimezone() {
        app.tapMenubarIcon()
        app.buttons["Preferences"].click()
        
        deleteAllTimezones()
        
        XCTAssertTrue(app.staticTexts["NoTimezoneEmoji"].exists)
        XCTAssertTrue(app.staticTexts["NoTimezoneMessage"].exists)
        
        app.tapMenubarIcon()
        XCTAssertTrue(app.buttons["EmptyAddTimezone"].exists)
        
        addAPlace(place: "Omaha", to: app)
        addAPlace(place: "Mumbai", to: app)
        
        deleteAllTimezones()
        
        XCTAssertTrue(app.staticTexts["NoTimezoneEmoji"].exists)
        XCTAssertTrue(app.staticTexts["NoTimezoneMessage"].exists)
        
        addAPlace(place: "Omaha", to: app)
        addAPlace(place: "Mumbai", to: app)
    }
    
    func testWarningIfMoreThanOneMenubarIsSelected() {
        app.tapMenubarIcon()
        app.buttons["Preferences"].click()
        
        let preferencesTable = app.tables["TimezoneTableView"]
        XCTAssertTrue(preferencesTable.exists)
        
        // Let's reset all checkboxes
        let favouritedMenubarsQuery = preferencesTable.checkBoxes.matching(NSPredicate(format: "value == 1", ""))
        
        if favouritedMenubarsQuery.count > 1 {
            for _ in 0..<favouritedMenubarsQuery.count {
                let checkbox = favouritedMenubarsQuery.element(boundBy: 0)
                checkbox.click()
            }
        }
        
        // Let's make sure we have > 1 timezones first
        let favourites = preferencesTable.tableRows
        XCTAssertTrue(favourites.count > 1)
        
        // Select two timezones
        let unfavouritedMenubarsQuery = preferencesTable.checkBoxes.matching(NSPredicate(format: "value == 0", ""))
        
        if unfavouritedMenubarsQuery.count > 1 {
            for _ in 0..<2{
                let checkbox = unfavouritedMenubarsQuery.element(boundBy: 0)
                checkbox.click()
            }
        }
        
        XCTAssertTrue(app.dialogs.count > 0)
        
        let compactModeButton = app.dialogs.buttons["Enable Compact Mode"]
       
        if compactModeButton.isHittable {
           compactModeButton.click()
           XCTAssertTrue(app.dialogs.count == 0)
        }
    }
    
    private func deleteAllTimezones() {
        let clockerWindow = app.windows["Clocker"]
        let rowQueryCount = clockerWindow.tables["TimezoneTableView"].tableRows.count
        
        if rowQueryCount > 0 {
            
            let currentElement = clockerWindow.tables["TimezoneTableView"].tableRows.firstMatch
            currentElement.click()
            
            for _ in 0 ..< rowQueryCount {
                clockerWindow.typeKey(XCUIKeyboardKey.delete,
                                      modifierFlags: XCUIElement.KeyModifierFlags())
            }
            
        }
    }
}

extension XCUIApplication {
    func tapMenubarIcon() {
        if menuBars.count < 2 {
            XCTFail("Unable to find menubar options")
        }

        statusItems.firstMatch.click()
    }
}
