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
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker1") else {
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
                                  days: 8,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let oldDate = Date().subtract(dateChunk)
        
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker2") else {
            return
        }
        mockDefaults.set(oldDate, forKey: "install")
        ReviewController.applicationDidLaunch(mockDefaults)
        
        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        
        XCTAssertNil(mockDefaults.object(forKey:"last-prompt"))
        XCTAssertNil(mockDefaults.object(forKey:"last-version"))
        XCTAssertTrue(ReviewController.canPrompt())
    }
    
    func testPromptDisplayAfterTwoMonths() {
        let dateChunk = TimeChunk(seconds: 0,
                                  minutes: 0,
                                  hours: 0,
                                  days: 68,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let minInstall = Date().subtract(dateChunk)
        
        let promptChunk = TimeChunk(seconds: 0,
                                  minutes: 0,
                                  hours: 0,
                                  days: 60,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let lastPromptDate = Date().subtract(promptChunk)
        
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker3") else {
            return
        }
        mockDefaults.set(minInstall, forKey: "install")
        mockDefaults.set("test-version", forKey: "last-version")
        mockDefaults.set(lastPromptDate, forKey: "last-prompt")
        ReviewController.applicationDidLaunch(mockDefaults)
        
        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        XCTAssertFalse(ReviewController.canPrompt())
    }
    
    func testPrompDisplayedAfterThreeMonths() {
        let dateChunk = TimeChunk(seconds: 0,
                                  minutes: 0,
                                  hours: 0,
                                  days: 98,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let minInstall = Date().subtract(dateChunk)
        
        let promptChunk = TimeChunk(seconds: 0,
                                  minutes: 0,
                                  hours: 0,
                                  days: 91,
                                  weeks: 0,
                                  months: 0,
                                  years: 0)
        let lastPromptDate = Date().subtract(promptChunk)
        
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker4") else {
            return
        }
        mockDefaults.set(minInstall, forKey: "install")
        mockDefaults.set("test-version", forKey: "last-version")
        mockDefaults.set(lastPromptDate, forKey: "last-prompt")
        ReviewController.applicationDidLaunch(mockDefaults)
        
        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        
        XCTAssertNotNil(mockDefaults.object(forKey:"last-prompt"))
        XCTAssertNotNil(mockDefaults.object(forKey:"last-version"))
        XCTAssertTrue(ReviewController.canPrompt())
    }
    
    func testPrompted() {
        guard let mockDefaults = UserDefaults(suiteName: "com.test.Clocker5") else {
            return
        }
        ReviewController.applicationDidLaunch(mockDefaults)
        ReviewController.prompt()
        XCTAssertNotNil(mockDefaults.object(forKey:"last-prompt"))
        XCTAssertNotNil(mockDefaults.object(forKey:"last-version"))
    }

}
