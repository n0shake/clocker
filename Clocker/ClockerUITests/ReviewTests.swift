// Copyright © 2015 Abhishek Banthia

import XCTest

class ReviewTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append(CLUITestingLaunchArgument)
        app.launch()

        app.tapMenubarIcon()
        app.tapMenubarIcon()
        app.tapMenubarIcon()
    }

    func testIfReviewIsNegativeAndUserWantsToProvideFeedback() {

        guard app.buttons["Not Really"].exists else { return }
        XCTAssertTrue(app.staticTexts["ReviewLabel"].exists)
        app.buttons["Not Really"].click()
        sleep(2)
        app.buttons["Yes?"].click()
        XCTAssertFalse(app.staticTexts["ReviewLabel"].exists)
        XCTAssertTrue(app.windows["Clocker Feedback"].exists)
    }

    func testIfReviewIsNegativeAndNoFeedback() {
        guard app.buttons["Not Really"].exists else { return }
        XCTAssertTrue(app.staticTexts["ReviewLabel"].exists)
        app.buttons["Not Really"].click()
        sleep(2)
        app.buttons["No, thanks"].click()
        XCTAssertFalse(app.staticTexts["ReviewLabel"].exists)
    }

    func testOnPositiveReviewAndNoAction() {
        guard app.buttons["Yes!"].exists else { return }
        XCTAssertTrue(app.staticTexts["ReviewLabel"].exists)
        app.buttons["Yes!"].click()
        sleep(2)
        app.buttons["No, thanks"].click()
        XCTAssertFalse(app.staticTexts["ReviewLabel"].exists)
    }

    func testOnPositiveReviewAndAction() {
        guard app.buttons["Yes!"].exists else { return }
        XCTAssertTrue(app.staticTexts["ReviewLabel"].exists)
        app.buttons["Yes!"].click()
        sleep(2)
        app.buttons["Yes"].click()
        XCTAssertFalse(app.staticTexts["ReviewLabel"].exists)
    }

}
