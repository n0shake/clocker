// Copyright © 2015 Abhishek Banthia

import XCTest

let CLUITestingLaunchArgument = "isUITesting"

class PanelTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        if app.tables["FloatingTableView"].exists {
            app.buttons["FloatingPin"].click()
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPinningPanelAndBack() {
        app.tapMenubarIcon()

        app.buttons["Pin"].click()

        XCTAssertTrue(app.tables["FloatingTableView"].exists, "Floating Table unexpectedly doesn't exist.")

        app.buttons["FloatingPin"].click()

        app.tapMenubarIcon()

        XCTAssertTrue(app.tables["mainTableView"].exists, "Main Table unexpectedly doesn't exist")
    }

    func testChangingLabelFromPopover() {
        app.tapMenubarIcon()

        let cell = app.tables["mainTableView"].cells.firstMatch
        let originalField = cell.staticTexts["CustomNameLabelForCell"]

        guard let originalValue = originalField.value as? String else {
            XCTFail("Original Field's value was unexpectedly nil")
            return
        }

        cell.buttons["extraOptionButton"].click()

        XCTAssertTrue(app.textFields["CustomLabel"].exists, "Custom Label doesn't exist.")

        app.textFields["CustomLabel"].reset(text: "My Precious")
        app.buttons["SaveButton"].click()

        let verifyCell = app.tables["mainTableView"].cells.firstMatch
        let newField = verifyCell.staticTexts["CustomNameLabelForCell"]

        if let newFieldValue = newField.value as? String {
            XCTAssertTrue(newFieldValue == "My Precious", "Labels don't match")
        }

        cell.buttons["extraOptionButton"].click()
        app.textFields["CustomLabel"].reset(text: originalValue)
        app.buttons["SaveButton"].click()
    }

    func testEnablingUpcomingEventView() {
        app.tapMenubarIcon()

        let upcomingView = app.collectionViews["UpcomingEventCollectionView"]
        let beforeUpcomingEventViewExist = upcomingView.exists

        app.buttons["Preferences"].click()

        let clockerWindow = app.windows["Clocker"]
        let toolbarsQuery = clockerWindow.toolbars.buttons
        toolbarsQuery.element(boundBy: 2).click()

        if app.windows["Clocker"].staticTexts["InfoField"].exists {
            /* We haven't provided calendar access to the app*/
            return
        }

        let yesPredicate = NSPredicate(format: "title like %@", "Yes")
        let noPredicate = NSPredicate(format: "title like %@", "No")

        let elementsMatching = clockerWindow.radioGroups.firstMatch.radioButtons

        let yesBar = elementsMatching.element(matching: yesPredicate)

        if let selection = yesBar.value as? Int, selection == 1 {
            let noBar = elementsMatching.element(matching: noPredicate)
            noBar.click()
        } else {
            yesBar.click()
        }

        clockerWindow.buttons[XCUIIdentifierCloseWindow].click()

        app.tapMenubarIcon()

        let newUpcomingEventView = app.collectionViews["UpcomingEventCollectionView"]
        let afterUpcomingEventViewExists = newUpcomingEventView.exists

        XCTAssertNotEqual(afterUpcomingEventViewExists, beforeUpcomingEventViewExist)
    }

    func testRightMouseDownToShowPopover() {
        app.tapMenubarIcon()

        let cell = app.tables["mainTableView"].cells.firstMatch
        cell.rightClick()

        XCTAssert(app.popovers.count > 0)
    }

    // Ensure that once main panel is closed, the time in the menubar doesn't stop and stays up-to-date
    func testTimeIsUpToDate() {
        // Ensure that we have seconds selected for the timezone format
        // Open Panel; before closing panel note the time
        // Close Panel;
        // Start timer;
        // Check time increments or is not equal for all those five seconds?
    }
}
