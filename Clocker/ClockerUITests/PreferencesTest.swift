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
            return
        }

        app.windows["Clocker"].tables["TimezoneTableView"].tableRows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).click()

        XCTAssertTrue(app.checkBoxes["DeleteTimezone"].isEnabled)
    }

    func testAddingATimezone() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        addAPlace(place: "UTC", to: app)

        let matchPredicate = NSPredicate(format: "value contains %@", "UTC")
        let matchingFields = app.tables["TimezoneTableView"].textFields.matching(matchPredicate)
        XCTAssertTrue(matchingFields.count > 0, "Matching Fields count was zero")

        deleteAPlace(place: "UTC", for: app)
    }

    func testSortingCitiesByTimezoneDifference() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        deleteAllPlaces(app: app)

        addAPlace(place: "New Zealand", to: app)
        addAPlace(place: "San Francisco", to: app)
        addAPlace(place: "Florida", to: app, shouldSleep: false) // Last elements don't need to sleep

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Time Difference".localizedString()].exists)

        app.windows["Clocker"].checkBoxes["Sort by Time Difference".localizedString()].click()

        var actualLabels: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                actualLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualLabels,
                       ["New Zealand".localizedString(),
                        "Florida".localizedString(),
                        "San Francisco".localizedString()])

        app.windows["Clocker"].checkBoxes["Sort by Time Difference".localizedString()].click()

        var actualReversedLabels: [String] = []
        let newReversedQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newReversedQuery.count {
            if let currentValue = newReversedQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                actualReversedLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualReversedLabels, ["San Francisco".localizedString(),
                                              "Florida".localizedString(),
                                              "New Zealand".localizedString()])

        addAPlace(place: "Omaha", to: app)
        addAPlace(place: "Mumbai", to: app)
    }

    func testSortingCitiesByTimezoneName() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Time Difference".localizedString()].exists)
        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].exists)
        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Name".localizedString()].exists)

        var formattedAddress: [String] = []

        let formattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< formattedAddressQuery.count {
            if let currentValue = formattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                formattedAddress.append(currentValue)
            }
        }

        formattedAddress.sort()

        if let value = app.windows["Clocker"].checkBoxes["Sort by Name".localizedString()].value as? Int, value == 0 {
            app.windows["Clocker"].checkBoxes["Sort by Name".localizedString()].click()
        }

        var newformattedAddress: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 0 {
                newformattedAddress.append(currentValue)
            }
        }

        XCTAssertEqual(newformattedAddress, formattedAddress)
    }

    func testSortingCitiesByCustomLabel() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        addAPlace(place: "Aurangabad", to: app)
        addAPlace(place: "Zimbabwe", to: app)
        addAPlace(place: "Portland", to: app, shouldSleep: false)
        addAPlace(place: "Asia/Calcutta", to: app)
        addAPlace(place: "Anywhere on Earth", to: app, shouldSleep: false)

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].exists)

        var expectedLabels: [String] = []

        let formattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< formattedAddressQuery.count {
            if let currentValue = formattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 1 {
                expectedLabels.append(currentValue)
            }
        }

        expectedLabels.sort()

        if let value = app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].value as? Int, value == 0 {
            app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].click()
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
        deleteAPlace(place: "Portland", for: app)
        deleteAPlace(place: "Asia/Calcutta", for: app)
        deleteAPlace(place: "Anywhere on Earth", for: app, shouldSleep: false)
    }

    func testSortingTimezonesByCustomLabel() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        addAPlace(place: "Europe/Lisbon", to: app)
        addAPlace(place: "Asia/Calcutta", to: app)
        addAPlace(place: "Anywhere on Earth", to: app, shouldSleep: false)

        XCTAssertTrue(app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].exists)

        var expectedLabels: [String] = []

        let formattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< formattedAddressQuery.count {
            if let currentValue = formattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 1 {
                expectedLabels.append(currentValue)
            }
        }

        expectedLabels.sort()

        if let value = app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].value as? Int, value == 0 {
            app.windows["Clocker"].checkBoxes["Sort by Label".localizedString()].click()
        }

        var actualLabels: [String] = []
        let newFormattedAddressQuery = app.windows["Clocker"].textFields

        for elementIndex in 0 ..< newFormattedAddressQuery.count {
            if let currentValue = newFormattedAddressQuery.element(boundBy: elementIndex).value as? String, elementIndex % 2 == 1 {
                actualLabels.append(currentValue)
            }
        }

        XCTAssertEqual(actualLabels, expectedLabels)

        deleteAPlace(place: "Europe/Lisbon", for: app)
        deleteAPlace(place: "Asia/Calcutta", for: app)
        deleteAPlace(place: "Anywhere on Earth", for: app, shouldSleep: false)
    }

    func testSearchingWithMisspelledName() {
        app.tapMenubarIcon()
        app.tables["mainTableView"].typeKey(",", modifierFlags: .command)

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        let searchField = app.searchFields["AvailableSearchField"]
        searchField.reset(text: "StuJjlqh7AcJFnBuOdgNa2dQ4WrIajP9Mo8R83FV7fIZ3B8zE2n")

        sleep(2)

        let maxCharacterCountPredicate = NSPredicate(format: "value like %@", "Max Search Characters".localizedString())
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
            for _ in 0 ..< favouritedMenubarsQuery.count {
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
            for _ in 0 ..< 2 {
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
            // Table Rows aren't hittable in Xcode 12.0 (10/7/20) and so we need to find a closer co-ordinate and perform click()
            let currentElement = clockerWindow.tables["TimezoneTableView"].tableRows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
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
            return
        }

        statusItems.firstMatch.click()
    }
}

extension XCTestCase {
    func inverseWaiterFor(element: XCUIElement, time: TimeInterval = 25) {
        let spinnerPredicate = NSPredicate(format: "exists == false")
        let spinnerExpectation = expectation(for: spinnerPredicate, evaluatedWith: element, handler: nil)
        let spinnerResult = XCTWaiter().wait(for: [spinnerExpectation], timeout: time)

        if spinnerResult != .completed {
            XCTFail("Still seeing Spinner after 25 seconds. Something's wrong")
            return
        }
    }

    func addAPlace(place: String, to app: XCUIApplication, shouldSleep: Bool = true) {
        // Let's first check if the place is already present in the list

        let matchPredicate = NSPredicate(format: "value contains %@", place)
        let matchingFields = app.windows["Clocker"].tables["TimezoneTableView"].textFields.matching(matchPredicate)
        if matchingFields.count > 0 {
            return
        }

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        let searchField = app.searchFields["AvailableSearchField"]
        if searchField.isHittable {
            searchField.reset(text: place)
        }

        let results = app.tables["AvailableTimezoneTableView"].cells.staticTexts.matching(matchPredicate)

        let waiter = XCTWaiter()
        let isHittable = NSPredicate(format: "exists == true", "")
        let addExpectation = expectation(for: isHittable,
                                         evaluatedWith: results.firstMatch) { () -> Bool in
            print("Handler called")
            return true
        }

        waiter.wait(for: [addExpectation], timeout: 5)

        if results.count > 0 {
            results.firstMatch.click()
        }

        if app.buttons["AddAvailableTimezone"].exists {
            app.buttons["AddAvailableTimezone"].click()
        }

        if shouldSleep {
            sleep(2)
        }
    }

    func deleteAllPlaces(app: XCUIApplication) {
        var rowQueryCount = app.windows["Clocker"].tables["TimezoneTableView"].tableRows.count
        if rowQueryCount == 0 {
            return
        }

        let currentElement = app.windows["Clocker"].tableRows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        currentElement.click()

        while rowQueryCount > 0 {
            app.windows["Clocker"].typeKey(XCUIKeyboardKey.delete, modifierFlags: XCUIElement.KeyModifierFlags())
            rowQueryCount -= 1
        }
    }

    func deleteAPlace(place: String, for app: XCUIApplication, shouldSleep: Bool = true) {
        let userPrefferedLanguage = Locale.preferredLanguages.first ?? "en-US"
        if !userPrefferedLanguage.lowercased().contains("en") {
            // We're testing in a different user language. We can't do string matching here.
            // Delete the last row
            let rowCount = app.tables["TimezoneTableView"].tableRows.count
            let rowToDelete = app.tables["TimezoneTableView"].tableRows.element(boundBy: rowCount - 1)
            deleteAtRow(rowToDelete, for: app, shouldSleep: shouldSleep)
            return
        }

        let matchPredicate = NSPredicate(format: "value contains %@", place)
        let row = app.tables["TimezoneTableView"].textFields.matching(matchPredicate).firstMatch
        deleteAtRow(row, for: app, shouldSleep: shouldSleep)
    }

    private func deleteAtRow(_ rowToDelete: XCUIElement, for _: XCUIApplication, shouldSleep: Bool) {
        rowToDelete.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).click()
        rowToDelete.typeKey(XCUIKeyboardKey.delete, modifierFlags: XCUIElement.KeyModifierFlags())
        if shouldSleep {
            sleep(2)
        }
    }
}
