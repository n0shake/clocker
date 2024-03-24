// Copyright © 2015 Abhishek Banthia

import XCTest

class CopyToClipboardTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        if app.tables["FloatingTableView"].exists == false {
            app.tapMenubarIcon()
            app.buttons["Pin"].click()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFullCopy() throws {
        let cell = app.tables["FloatingTableView"].cells.firstMatch
        let customLabel = cell.staticTexts["CustomNameLabelForCell"]
        guard let value = customLabel.value else { return }
        let time = cell.staticTexts["ActualTime"].value ?? "Nil Value"
        let expectedValue = "\(value) - \(time)"

        // Tap to copy!
        cell.click()

        let actualValue = NSPasteboard.general.string(forType: .string) ?? "Empty Pasteboard"
        XCTAssert(expectedValue == actualValue,
                  "Clipboard value (\(actualValue)) doesn't match expected result: \(expectedValue)")

        // Test full copy
        let cellCount = app.tables["FloatingTableView"].cells.count
        var clipboardValue: [String] = []
        for cellIndex in 0 ..< cellCount {
            let cell = app.tables["FloatingTableView"].cells.element(boundBy: cellIndex)
            let time = cell.staticTexts["ActualTime"].value ?? "Nil Value"
            clipboardValue.append("\(time)")
        }
        
        

        app.buttons["Share"].click()
    }

    func testModernSlider() {
        if app.buttons["FloatingPin"].exists {
            app.buttons["FloatingPin"].click()
        }

        app.tapMenubarIcon()
        let modernSliderExists = app.collectionViews["ModernSlider"].exists
        app.buttons["Preferences"].click()

        let appearanceTab = app.toolbars.buttons.element(boundBy: 1)
        appearanceTab.click()

        let miscTab = app.tabs.element(boundBy: 1)
        miscTab.click()

        if modernSliderExists {
            app.radioGroups["FutureSlider"].radioButtons["Hide"].click()
        } else {
            app.radioGroups["FutureSlider"].radioButtons["Show"].click()
        }

        app.tapMenubarIcon()

        let newFloatingSliderExists = app.collectionViews["ModernSlider"].exists
        XCTAssertNotEqual(newFloatingSliderExists, modernSliderExists)
    }
}
