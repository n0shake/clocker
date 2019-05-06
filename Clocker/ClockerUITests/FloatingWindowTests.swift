// Copyright © 2015 Abhishek Banthia

import XCTest

class FloatingWindowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append(CLUITestingLaunchArgument)
        app.launch()

        if !app.tables["FloatingTableView"].exists {
            app.tapMenubarIcon()
            app.buttons["Pin"].click()
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    func testFloatingWindow() {
        let cell = app.tables["FloatingTableView"].cells.firstMatch

        let extraOptionButton = cell.buttons.firstMatch
        extraOptionButton.click()

        let remindersCheckbox = app.checkBoxes["ReminderCheckbox"]
        remindersCheckbox.click()

        sleep(1)

        XCTAssertTrue(app.popovers.datePickers.firstMatch.isEnabled)
        remindersCheckbox.click()

        sleep(1)
        XCTAssertFalse(app.popovers.datePickers.firstMatch.isEnabled)
    }

    func testAddingANote() {
        let expectedText = "This is a really important note to me and my friends"

        if app.buttons["Pin"].exists {
            app.buttons["Pin"].click()
        }

        let cell = app.tables["FloatingTableView"].cells.firstMatch
        let extraOptionButton = cell.buttons.firstMatch
        extraOptionButton.click()

        let notesTextView = app.textViews["NotesTextView"]
        notesTextView.click()
        app.textViews["NotesTextView"].click(forDuration: 2, thenDragTo: notesTextView)
        notesTextView.reset(text: "This is a really important note to me and my friends")

        let saveButton = app.buttons["SaveButton"]
        saveButton.click()

        if let noteLabelInCell = cell.staticTexts["This is a really important note to me and my friends"].value as? String {
            XCTAssert(noteLabelInCell == expectedText)
        }
    }

    func testSettingAReminder() {
        if app.buttons["Pin"].exists {
            app.buttons["Pin"].click()
        }

        let cell = app.tables["FloatingTableView"].cells.firstMatch
        let extraOptionButton = cell.buttons.firstMatch
        extraOptionButton.click()

        let remindersCheckbox = app.checkBoxes["ReminderCheckbox"]
        remindersCheckbox.click()

        app.buttons["SaveButton"].click()

        app.tapMenubarIcon()
    }

    func testMarkingSlider() {
        if app.buttons["Pin"].exists {
            app.buttons["Pin"].click()
        }

        let floatingSlider = app.sliders["FloatingSlider"].exists
        app.buttons["FloatingPreferences"].click()

        let appearanceTab = app.toolbars.buttons.element(boundBy: 1)
        appearanceTab.click()

        if floatingSlider {
            app.radioGroups["FutureSlider"].radioButtons["No"].click()
        } else {
            app.radioGroups["FutureSlider"].radioButtons["Yes"].click()
        }

        let newFloatingSliderExists = app.sliders["FloatingSlider"].exists

        XCTAssertNotEqual(floatingSlider, newFloatingSliderExists)
    }

    func testHidingMenubarOptions() {
        if app.buttons["Pin"].exists {
            app.buttons["Pin"].click()
        }

        app.buttons["FloatingPreferences"].click()
        app.windows["Clocker"].toolbars.buttons["General"].click()

        let menubarDisplayQuery = app.tables.checkBoxes.matching(NSPredicate(format: "value == 1", ""))
        let menubarDisplayQueryCount = menubarDisplayQuery.count

        for index in 0 ..< menubarDisplayQueryCount where index < menubarDisplayQueryCount {
            menubarDisplayQuery.element(boundBy: 0).click()
            sleep(1)
        }

        let appearanceTab = app.toolbars.buttons.element(boundBy: 1)
        appearanceTab.click()

        XCTAssertTrue(app.staticTexts["InformationLabel"].exists)

        let generalTab = app.toolbars.buttons.element(boundBy: 0)
        generalTab.click()

        app.tables["TimezoneTableView"].checkBoxes.firstMatch.click()

        appearanceTab.click()

        XCTAssertFalse(app.staticTexts["InformationLabel"].exists)
    }

    func testMovingSlider() {
        if app.buttons["Pin"].exists {
            app.buttons["Pin"].click()
        }

        let floatingSlider = app.sliders["FloatingSlider"].exists

        if floatingSlider {
            let tomorrowPredicate = NSPredicate(format: "placeholderValue like %@", "Tomorrow")
            let tomorrow = app.tables.tableRows.staticTexts.matching(tomorrowPredicate)

            var previousValues: [String] = []

            for index in 0 ..< tomorrow.count {
                let element = tomorrow.element(boundBy: index)
                guard let supplementaryText = element.value as? String else {
                    continue
                }
                previousValues.append(supplementaryText)
            }

            app.sliders["FloatingSlider"].adjust(toNormalizedSliderPosition: 0.7)
            sleep(1)
            app.sliders["FloatingSlider"].adjust(toNormalizedSliderPosition: 1)

            let newTomorrow = app.tables.tableRows.staticTexts.matching(tomorrowPredicate)

            var newValues: [String] = []

            for index in 0 ..< newTomorrow.count {
                let element = newTomorrow.element(boundBy: index)
                guard let supplementaryText = element.value as? String else {
                    continue
                }
                newValues.append(supplementaryText)
            }

            XCTAssertNotEqual(newValues, previousValues)
        }
    }
}

extension XCUIElement {
    func reset(text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        if let hasKeyboardFocus = value(forKey: "hasKeyboardFocus") as? Bool, hasKeyboardFocus == false {
            click()
        }

        for _ in 0 ..< stringValue.count {
            typeKey(XCUIKeyboardKey.delete, modifierFlags: XCUIElement.KeyModifierFlags())
        }

        guard let newStringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        for _ in 0 ..< newStringValue.count {
            typeKey(XCUIKeyboardKey.forwardDelete, modifierFlags: XCUIElement.KeyModifierFlags())
        }

        typeText(text)
    }
}
