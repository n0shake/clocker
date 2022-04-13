// Copyright © 2015 Abhishek Banthia

@testable import Clocker
import EventKit
import XCTest

class EventInfoTests: XCTestCase {
    private let eventStore = EKEventStore()

    func testMetadataForUpcomingEventHappeningInFiveMinutes() throws {
        let futureChunk = TimeChunk(seconds: 10, minutes: 5, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(futureChunk)

        let mockEventInfo = EventInfo(event: mockEvent,
                                      isAllDay: false,
                                      meetingURL: nil,
                                      attendeStatus: .accepted)
        XCTAssert(mockEventInfo.metadataForMeeting() == "in 5m",
                  "Metadata for meeting: \(mockEventInfo.metadataForMeeting()) doesn't match expectation")
    }

    func testMetadataForUpcomingEventHappeningInTenSeconds() throws {
        let futureChunk = TimeChunk(seconds: 10, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(futureChunk)

        let mockEventInfo = EventInfo(event: mockEvent,
                                      isAllDay: false,
                                      meetingURL: nil,
                                      attendeStatus: .accepted)
        XCTAssert(mockEventInfo.metadataForMeeting() == "in <1m",
                  "Metadata for meeting: \(mockEventInfo.metadataForMeeting()) doesn't match expectation")
    }

    func testMetadataForEventPastTwoMinutes() throws {
        let pastChunk = TimeChunk(seconds: 10, minutes: 2, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().subtract(pastChunk)

        let mockEventInfo = EventInfo(event: mockEvent,
                                      isAllDay: false,
                                      meetingURL: nil,
                                      attendeStatus: .accepted)
        XCTAssert(mockEventInfo.metadataForMeeting() == "started +2m.",
                  "Metadata for meeting: \(mockEventInfo.metadataForMeeting()) doesn't match expectation")
    }

    func testMetadataForEventPastTenMinutes() throws {
        let pastChunk = TimeChunk(seconds: 10, minutes: 10, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().subtract(pastChunk)

        let mockEventInfo = EventInfo(event: mockEvent,
                                      isAllDay: false,
                                      meetingURL: nil,
                                      attendeStatus: .accepted)
        XCTAssert(mockEventInfo.metadataForMeeting() == "Error",
                  "Metadata for meeting: \(mockEventInfo.metadataForMeeting()) doesn't match expectation")
    }

    func testMetadataForEventHappeningTomorrow() throws {
        let pastChunk = TimeChunk(seconds: 10, minutes: 0, hours: 25, days: 0, weeks: 0, months: 0, years: 0)
        let mockEvent = EKEvent(eventStore: eventStore)
        mockEvent.title = "Mock Title"
        mockEvent.startDate = Date().add(pastChunk)

        let mockEventInfo = EventInfo(event: mockEvent,
                                      isAllDay: false,
                                      meetingURL: nil,
                                      attendeStatus: .accepted)
        XCTAssert(mockEventInfo.metadataForMeeting() == "in 25h",
                  "Metadata for meeting: \(mockEventInfo.metadataForMeeting()) doesn't match expectation")
    }
}
