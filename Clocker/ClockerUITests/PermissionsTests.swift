// Copyright © 2015 Abhishek Banthia

import XCTest

class PermissionsTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAcceptingCalendarPermissions() {
        if app.tables["FloatingTableView"].exists {
            app.buttons["FloatingPin"].click()
        }

        app.tapMenubarIcon()
        app/*@START_MENU_TOKEN@*/ .buttons["Preferences"]/*[[".dialogs[\"Clocker Panel\"].buttons[\"Preferences\"]",".buttons[\"Preferences\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .click()

        let clockerWindow = app.windows["Clocker"]

        // Check Permissions first
        let permissionsTab = clockerWindow.toolbars.buttons["Permissions"]
        permissionsTab.click()

        let grantButton = clockerWindow.buttons["CalendarGrantAccessButton"].firstMatch

        if grantButton.title == "Granted" || grantButton.title == "Denied" {
            return
        }

        let calendarButton = clockerWindow.toolbars.buttons["Calendar"]
        calendarButton.click()

        let showUpcomingEventView = clockerWindow.staticTexts["UpcomingEventView"]
        XCTAssertFalse(showUpcomingEventView.isHittable)

        clockerWindow.buttons["Grant Access"].click()
        clockerWindow.buttons["CalendarGrantAccessButton"].firstMatch.click()

        addUIInterruptionMonitor(withDescription: "Calendars Access") { alert -> Bool in
            let alertButton = alert.buttons["OK"]
            if alertButton.exists {
                alertButton.tap()
                return true
            }
            return false
        }

        calendarButton.click()
        XCTAssertTrue(showUpcomingEventView.isHittable)
    }

    func testAcceptingRemindersPermissions() {
        if app.tables["FloatingTableView"].exists {
            app.tapMenubarIcon()
            app.buttons["FloatingPin"].click()
        }
        app.tapMenubarIcon()
        app/*@START_MENU_TOKEN@*/ .buttons["Preferences"]/*[[".dialogs[\"Clocker Panel\"].buttons[\"Preferences\"]",".buttons[\"Preferences\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .click()

        let clockerWindow = app.windows["Clocker"]

        // Check Permissions first
        let permissionsTab = clockerWindow.toolbars.buttons["Permissions"]
        permissionsTab.click()

        let grantButton = clockerWindow.buttons["RemindersGrantAccessButton"].firstMatch

        if grantButton.title == "Granted" || grantButton.title == "Denied" {
            return
        }

        clockerWindow.buttons["RemindersGrantAccessButton"].firstMatch.click()

        addUIInterruptionMonitor(withDescription: "Reminders Access") { alert -> Bool in
            let alertButton = alert.buttons["OK"]
            if alertButton.exists {
                alertButton.tap()
                return true
            }
            return false
        }
    }
}
