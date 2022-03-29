// Copyright © 2015 Abhishek Banthia

import XCTest
@testable import Clocker

class ReviewControllerTests: XCTestCase {
    func testDebuggingMode() throws {
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker") else {
            return
        }
        ReviewController.applicationDidLaunch(mockDefaults)
        
        // Call it again to ensure Keys.install
        ReviewController.applicationDidLaunch(mockDefaults)
        
        ReviewController.setPreviewMode(true)
        XCTAssertTrue(ReviewController.canPrompt())
    }
    
    func testPromptNotDisplayedInFirstWeekSinceInstall() {
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker") else {
            return
        }
        // Set key install time
        ReviewController.applicationDidLaunch(mockDefaults)
        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        
        XCTAssertFalse(ReviewController.canPrompt())
    }
    
    func testPrompDisplayedAfterFirstWeekOfInstall() {
        let dateChunk = TimeChunk(seconds: 0,
                                  minutes: 0,
                                  hours: 0,
                                  days: -7,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let oldDate = Date().subtract(dateChunk)
        
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker") else {
            return
        }
        mockDefaults.set(oldDate, forKey: "install")
        
        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        
        XCTAssertNil(mockDefaults.object(forKey:"last-prompt"))
        XCTAssertNil(mockDefaults.object(forKey:"last-version"))
        XCTAssertTrue(ReviewController.canPrompt())
    }

}
