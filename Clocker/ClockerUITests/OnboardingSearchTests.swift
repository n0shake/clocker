// Copyright © 2015 Abhishek Banthia

import XCTest

class OnboardingSearchTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append(CLOnboardingTestsLaunchArgument)
        app.launch()

        // Let's go to the Search View
        moveForward()
        moveForward()
        moveForward()
    }

    func testRegularSearch() throws {
        let searchField = app.searchFields["MainSearchField"]
        searchField.reset(text: "Paris")
        searchField.typeKey(XCUIKeyboardKey.return, modifierFlags: XCUIElement.KeyModifierFlags())

        sleep(2) // Wait for the query to return

        let results = app.tables["ResultsTableView"]
        let firstResult = results.cells.firstMatch
        XCTAssertTrue(results.cells.count > 0)

        let resultsPredicate = NSPredicate(format: "value CONTAINS 'Paris'", "")
        XCTAssertTrue(firstResult.staticTexts.matching(resultsPredicate).count > 0)

        // Let's retrieve the tap and add it!
        firstResult.doubleClick()

        sleep(2) // Wait for the Undo button to appear

        // Ensure Added Text is shown properly!
        let predicate = NSPredicate(format: "value BEGINSWITH 'Added'", "")
        let successTextShown = app.staticTexts.containing(predicate)
        XCTAssertTrue(successTextShown.count > 0)
    }

    func testUndoSearch() throws {
        let searchField = app.searchFields["MainSearchField"]
        searchField.reset(text: "Seoul")
        searchField.typeKey(XCUIKeyboardKey.return, modifierFlags: XCUIElement.KeyModifierFlags())

        sleep(2) // Wait for the query to return

        let results = app.tables["ResultsTableView"]
        let firstResult = results.cells.firstMatch
        XCTAssertTrue(results.cells.count > 0)

        let resultsPredicate = NSPredicate(format: "value CONTAINS 'Seoul'", "")
        XCTAssertTrue(firstResult.staticTexts.containing(resultsPredicate).count > 0)

        // Let's retrieve the tap and add it!
        firstResult.doubleClick()

        sleep(2) // Wait for the Undo button to appear

        // Ensure Added Text is shown properly!
        let predicate = NSPredicate(format: "value BEGINSWITH 'Added'", "")
        let successTextShown = app.staticTexts.containing(predicate)
        XCTAssertTrue(successTextShown.count > 0)

        let undoButton = app.buttons.matching(identifier: "UndoButton").firstMatch
        undoButton.click()

        // Ensure Removed Text is shown!
        let removedPredicate = NSPredicate(format: "value BEGINSWITH 'Removed.'", "")
        let removedText = app.staticTexts.containing(removedPredicate)
        XCTAssertTrue(removedText.count > 0)
    }

    func testMispelledCityNameSearch() throws {
        let searchField = app.searchFields["MainSearchField"]
        searchField.reset(text: "ajsdkjasdkjhasdkashkjdazasdasdas")
        searchField.typeKey(XCUIKeyboardKey.return, modifierFlags: XCUIElement.KeyModifierFlags())

        sleep(2) // Wait for the query to return

        let results = app.tables["ResultsTableView"]
        let firstResult = results.cells.firstMatch
        XCTAssertTrue(results.cells.count == 0)
        XCTAssertFalse(firstResult.staticTexts["Paris, France"].exists)

        sleep(2) // Wait for the Undo button to appear

        // Ensure Added Text is shown properly!
        let noErrorTextPredicate = NSPredicate(format: "value CONTAINS 'No results! 😔 Try entering the exact name.'", "")
        let noErrorText = app.staticTexts.containing(noErrorTextPredicate)
        XCTAssertTrue(noErrorText.count > 0)
    }

    private func moveForward() {
        let onboardingWindow = app.windows["OnboardingWindow"]
        onboardingWindow.buttons["Forward"].click()
        sleep(1)
    }
}
