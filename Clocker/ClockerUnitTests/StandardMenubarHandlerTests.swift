// Copyright © 2015 Abhishek Banthia

import CoreModelKit
import EventKit
import XCTest

@testable import Clocker

class StandardMenubarHandlerTests: XCTestCase {
    private let eventStore = EKEventStore()

    private let mumbai = ["customLabel": "Ghar",
                          "formattedAddress": "Mumbai",
                          "place_id": "ChIJwe1EZjDG5zsRaYxkjY_tpF0",
                          "timezoneID": "Asia/Calcutta",
                          "nextUpdate": "",
                          "latitude": "19.0759837",
                          "longitude": "72.8776559"]

    private func makeMockStore(with menubarMode: Int = 1) -> DataStore {
        // Wipe all timezones from UserDefaults
        let defaults = UserDefaults(suiteName: "com.abhishek.Clocker.StandardMenubarHandlerTests")!
        defaults.set(menubarMode, forKey: UserDefaultKeys.menubarCompactMode)
        defaults.set(0, forKey: UserDefaultKeys.showMeetingInMenubar)
        XCTAssertNotEqual(defaults, UserDefaults.standard)
        return DataStore(with: defaults)
    }

    private func saveObject(object: TimezoneData,
                            in store: DataStore,
                            at index: Int = -1)
    {
        var defaults = store.timezones()
        guard let encodedObject = NSKeyedArchiver.clocker_archive(with: object as Any) else {
            return
        }
        index == -1 ? defaults.append(encodedObject) : defaults.insert(encodedObject, at: index)
        store.setTimezones(defaults)
    }

    func testValidStandardMenubarHandler_returnMenubarTitle() {
        let store = makeMockStore()
        store.setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)

        let menubarTimezones = store.menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 1, "Count is \(String(describing: menubarTimezones?.count))")
    }

    func testUnfavouritedTimezone_returnEmptyMenubarTimezoneCount() {
        let store = makeMockStore()
        // Wipe all timezones from UserDefaults
        store.setTimezones(nil)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        saveObject(object: dataObject, in: store)

        let menubarTimezones = store.menubarTimezones()
        XCTAssertTrue(menubarTimezones?.count == 0)
    }

    func testUnfavouritedTimezone_returnNilMenubarString() {
        let store = makeMockStore()
        // Wipe all timezones from UserDefaults
        store.setTimezones(nil)
        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        let emptyMenubarString = menubarHandler.titleForMenubar()
        // Returns early because DataStore.menubarTimezones is nil
        XCTAssertNil(emptyMenubarString)

        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 0
        saveObject(object: dataObject, in: store)

        let menubarString = menubarHandler.titleForMenubar() ?? ""

        // Test menubar string is absent
        XCTAssertTrue(menubarString.count == 0)
    }

    func testWithEmptyMenubarTimezones() {
        let store = makeMockStore()
        store.setTimezones(nil)
        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssertNil(menubarHandler.titleForMenubar())
    }

    func testWithStandardMenubarMode() {
        // Set mode to standard mode
        let store = makeMockStore(with: 0)
        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssertNil(menubarHandler.titleForMenubar())
    }

    func testProviderPassingAllConditions() {
        // Set mode to standard mode
        let store = makeMockStore()
        // Save a menubar selected timezone
        let dataObject = TimezoneData(with: mumbai)
        dataObject.isFavourite = 1
        saveObject(object: dataObject, in: store)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssertNotNil(menubarHandler.titleForMenubar())
    }

    func testFormattedUpcomingEvent() {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 10, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(futureChunk)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssert(menubarHandler.format(event: mockEvent) == "Mock Title in 10m",
                  "Suffix \(menubarHandler.format(event: mockEvent)) doesn't match expectation")
    }

    func testUpcomingEventHappeningWithinOneMinute() {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 1, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(futureChunk)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssert(menubarHandler.format(event: mockEvent) == "Mock Title in 1m",
                  "Suffix \(menubarHandler.format(event: mockEvent)) doesn't match expectation")
    }

    func testUpcomingEventHappeningWithinSeconds() {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(futureChunk)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssert(menubarHandler.format(event: mockEvent) == "Mock Title starts now.",
                  "Suffix \(menubarHandler.format(event: mockEvent)) doesn't match expectation")
    }

    func testEmptyUpcomingEvent() {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.startDate = Date().add(futureChunk)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssert(menubarHandler.format(event: mockEvent) == UserDefaultKeys.emptyString,
                  "Suffix \(menubarHandler.format(event: mockEvent)) doesn't match expectation")
    }

    func testLongUpcomingEvent() {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Really long calendar event title that longer than the longest name"
        mockEvent.startDate = Date().add(futureChunk)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        XCTAssert(menubarHandler.format(event: mockEvent) == "Really long calendar event tit... starts now.",
                  "Suffix \(menubarHandler.format(event: mockEvent)) doesn't match expectation")
    }

    func testUpcomingEventHappeningInFiveMinutes() throws {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 5, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Event happening"
        mockEvent.calendar = EKCalendar(for: .event, eventStore: eventStore)
        mockEvent.startDate = Date().add(futureChunk)
        let eventInfo = EventInfo(event: mockEvent,
                                  isAllDay: false,
                                  meetingURL: nil,
                                  attendeStatus: .accepted)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        let calendar = Calendar.autoupdatingCurrent
        let events: [Date: [EventInfo]] = [calendar.startOfDay(for: Date()): [eventInfo]]
        let actualResult = try XCTUnwrap(menubarHandler.checkForUpcomingEvents(events, calendar: calendar))
        let expectedResult = "Event happening in 5m"
        XCTAssert(actualResult == expectedResult, "Actual Result \(actualResult)")
    }

    func testUpcomingEventHappeningIn29Minutes() throws {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 29, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Event happening"
        mockEvent.calendar = EKCalendar(for: .event, eventStore: eventStore)
        mockEvent.startDate = Date().add(futureChunk)
        let eventInfo = EventInfo(event: mockEvent,
                                  isAllDay: false,
                                  meetingURL: nil,
                                  attendeStatus: .accepted)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        let calendar = Calendar.autoupdatingCurrent
        let events: [Date: [EventInfo]] = [calendar.startOfDay(for: Date()): [eventInfo]]
        let actualResult = try XCTUnwrap(menubarHandler.checkForUpcomingEvents(events, calendar: calendar))
        let expectedResult = "Event happening in 29m"
        XCTAssert(actualResult == expectedResult, "Actual Result \(actualResult)")
    }

    func testUpcomingEventHappeningIn31Minutes() throws {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 31, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Event happening"
        mockEvent.calendar = EKCalendar(for: .event, eventStore: eventStore)
        mockEvent.startDate = Date().add(futureChunk)
        let eventInfo = EventInfo(event: mockEvent,
                                  isAllDay: false,
                                  meetingURL: nil,
                                  attendeStatus: .accepted)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        let calendar = Calendar.autoupdatingCurrent
        let events: [Date: [EventInfo]] = [calendar.startOfDay(for: Date()): [eventInfo]]
        XCTAssertNil(menubarHandler.checkForUpcomingEvents(events, calendar: calendar))
    }

    func testUpcomingEventHappeningIn31MinutesWithEmptyEvent() throws {
        let store = makeMockStore()

        let futureChunk = TimeChunk(seconds: 10, minutes: 31, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.startDate = Date().add(futureChunk)
        mockEvent.calendar = EKCalendar(for: .event, eventStore: eventStore)
        let eventInfo = EventInfo(event: mockEvent,
                                  isAllDay: false,
                                  meetingURL: nil,
                                  attendeStatus: .accepted)

        let menubarHandler = MenubarTitleProvider(with: store, eventStore: EventCenter.sharedCenter())
        let calendar = Calendar.autoupdatingCurrent
        let events: [Date: [EventInfo]] = [calendar.startOfDay(for: Date()): [eventInfo]]
        XCTAssertNil(menubarHandler.checkForUpcomingEvents(events, calendar: calendar))
    }
}
