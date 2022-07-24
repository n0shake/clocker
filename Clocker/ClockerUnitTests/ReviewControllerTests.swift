// Copyright © 2015 Abhishek Banthia

@testable import Clocker
import XCTest

class ReviewControllerTests: XCTestCase {
    func testDebuggingMode() throws {
        let mockSuite = "com.test.Clocker.\(randomLetter())"
        guard let mockDefaults = UserDefaults(suiteName: mockSuite) else {
            return
        }
        ReviewController.applicationDidLaunch(mockDefaults)

        // Call it again to ensure Keys.install
        ReviewController.applicationDidLaunch(mockDefaults)

        ReviewController.setPreviewMode(true)
        XCTAssertTrue(ReviewController.canPrompt())
        mockDefaults.removeSuite(named: mockSuite)
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
        let mockSuite = "com.test.Clocker2.\(randomLetter())"
        guard let mockDefaults = UserDefaults(suiteName: mockSuite) else {
            return
        }
        mockDefaults.set(oldDate, forKey: "install")
        ReviewController.applicationDidLaunch(mockDefaults)

        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)

        XCTAssertNil(mockDefaults.object(forKey: "last-prompt"))
        XCTAssertNil(mockDefaults.object(forKey: "last-version"))
        XCTAssertTrue(ReviewController.canPrompt())
        mockDefaults.removeSuite(named: mockSuite)
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

        let mockSuite = "com.test.Clocker3.\(randomLetter())"
        guard let mockDefaults = UserDefaults(suiteName: mockSuite) else {
            return
        }
        mockDefaults.set(minInstall, forKey: "install")
        mockDefaults.set("test-version", forKey: "last-version")
        mockDefaults.set(lastPromptDate, forKey: "last-prompt")
        ReviewController.applicationDidLaunch(mockDefaults)

        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)
        XCTAssertFalse(ReviewController.canPrompt())
        mockDefaults.removeSuite(named: mockSuite)
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

        let mockSuite = "com.test.Clocker4.\(randomLetter())"
        guard let mockDefaults = UserDefaults(suiteName: mockSuite) else {
            return
        }
        mockDefaults.set(minInstall, forKey: "install")
        mockDefaults.set("test-version", forKey: "last-version")
        mockDefaults.set(lastPromptDate, forKey: "last-prompt")
        ReviewController.applicationDidLaunch(mockDefaults)

        // Explicitly set preview mode to false
        ReviewController.setPreviewMode(false)

        XCTAssertNotNil(mockDefaults.object(forKey: "last-prompt"))
        XCTAssertNotNil(mockDefaults.object(forKey: "last-version"))
        XCTAssertTrue(ReviewController.canPrompt())
        mockDefaults.removeSuite(named: mockSuite)
    }

    func testPrompted() {
        let mockSuite = "com.test.Clocker5.\(randomLetter())"
        guard let mockDefaults = UserDefaults(suiteName: mockSuite) else {
            return
        }
        ReviewController.applicationDidLaunch(mockDefaults)
        ReviewController.prompt()
        XCTAssertNotNil(mockDefaults.object(forKey: "last-prompt"))
        XCTAssertNotNil(mockDefaults.object(forKey: "last-version"))
        mockDefaults.removeSuite(named: mockSuite)
    }

    private func randomLetter() -> String {
        let alphabet: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        return alphabet[Int(arc4random_uniform(26))]
    }
}
