// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import EventKit

extension EventCenter {
    func calendarAccessGranted() -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .authorized
    }

    func calendarAccessNotDetermined() -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .notDetermined
    }

    func calendarAccessDenied() -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .denied
    }

    func fetchSourcesAndCalendars() -> [Any] {
        var sourcesAndCalendars: [Any] = []

        // Fetch array of user's calendars sorted first by source title and then by calendar title
        let calendars = eventStore.calendars(for: .event).sorted { cal1, cal2 -> Bool in

            if cal1.source.sourceIdentifier == cal2.source.sourceIdentifier {
                return cal1.title < cal2.title
            }

            return cal1.source.title < cal2.source.title
        }

        // Now time to fetch the events
        // Fetch the user-selected calendars. Initially, all the calendars will be selected
        var setOfCalendars: Set<String> = Set()

        if let userCalendars = UserDefaults.standard.array(forKey: CLSelectedCalendars) as? [String], !userCalendars.isEmpty {
            setOfCalendars = Set(userCalendars)
        }

        var currentSourceTitle = CLEmptyString

        for calendar in calendars {
            if !(calendar.source.title == currentSourceTitle) {
                sourcesAndCalendars.append(calendar.source.title)
                currentSourceTitle = calendar.source.title
            }

            let isCalendarSelected = setOfCalendars.contains(calendar.calendarIdentifier)
            let calendarInfo = CalendarInfo(calendar: calendar, selected: isCalendarSelected)
            sourcesAndCalendars.append(calendarInfo)
        }

        return sourcesAndCalendars
    }

    func isThereAnUpcomingCalendarEvent() -> Bool {
        if DataStore.shared().shouldDisplay(.showMeetingInMenubar) {
            let filteredDates = EventCenter.sharedCenter().eventsForDate
            let autoupdatingCal = EventCenter.sharedCenter().autoupdatingCalendar
            guard let events = filteredDates[autoupdatingCal.startOfDay(for: Date())] else {
                return false
            }

            for event in events {
                if event.event.startDate.timeIntervalSinceNow > 0, !event.isAllDay {
                    let timeForEventToStart = event.event.startDate.timeIntervalSinceNow / 60

                    if timeForEventToStart > 30 {
                        Logger.info("Our next event: \(event.event.title ?? "Error") starts in \(timeForEventToStart) mins")
                        continue
                    }

                    return true
                }
            }
        }

        return false
    }

    /* Used for the compact menubar mode.
     Returns a tuple with 0 as the header string and 1 as the subtitle string
     */
    func separateFormat(event: EKEvent) -> (String, String)? {
        guard let truncateLength = DataStore.shared().retrieve(key: CLTruncateTextLength) as? NSNumber, let eventTitle = event.title else {
            return nil
        }

        let seconds = event.startDate.timeIntervalSinceNow
        var formattedTitle: String = CLEmptyString

        if eventTitle.count > truncateLength.intValue {
            let truncateIndex = eventTitle.index(eventTitle.startIndex, offsetBy: truncateLength.intValue)
            let truncatedTitle = String(eventTitle[..<truncateIndex])

            formattedTitle.append(truncatedTitle)
            formattedTitle.append("...")
        } else {
            formattedTitle.append(eventTitle)
        }

        var menubarText: String = CLEmptyString
        let minutes = seconds / 60

        if minutes > 2 {
            let suffix = String(format: " in %0.f mins", minutes)
            menubarText.append(suffix)
        } else if minutes == 1 {
            let suffix = String(format: " in %0.f min", minutes)
            menubarText.append(suffix)
        } else {
            menubarText.append(" starts now.")
        }

        return (formattedTitle, menubarText)
    }

    func format(event: EKEvent) -> String {
        guard let truncateLength = DataStore.shared().retrieve(key: CLTruncateTextLength) as? NSNumber, let eventTitle = event.title else {
            return CLEmptyString
        }

        let seconds = event.startDate.timeIntervalSinceNow

        var menubarText: String = CLEmptyString

        if eventTitle.count > truncateLength.intValue {
            let truncateIndex = eventTitle.index(eventTitle.startIndex, offsetBy: truncateLength.intValue)
            let truncatedTitle = String(eventTitle[..<truncateIndex])

            menubarText.append(truncatedTitle)
            menubarText.append("...")
        } else {
            menubarText.append(eventTitle)
        }

        let minutes = seconds / 60

        if minutes > 2 {
            let suffix = String(format: " in %0.f mins", minutes)
            menubarText.append(suffix)
        } else if minutes == 1 {
            let suffix = String(format: " in %0.f min", minutes)
            menubarText.append(suffix)
        } else {
            menubarText.append(" starts now.")
        }

        return menubarText
    }

    func nextOccuring(_: [EventInfo]) -> EventInfo? {
        if calendarAccessDenied() || calendarAccessNotDetermined() {
            return nil
        }

        let relevantEvents = filteredEvents[autoupdatingCalendar.startOfDay(for: Date())] ?? []

        let filteredEvents = relevantEvents.filter {
            $0.event.isAllDay == false && $0.event.endDate.timeIntervalSinceNow > 0
        }

        if filteredEvents.count == 1 { return filteredEvents.first }

        // If there are multiple events coming up, prefer the ones the currentUser has accepted
        let acceptedEvents = filteredEvents.filter {
            $0.attendeStatus == .accepted
        }
        let optionalEvents = filteredEvents.filter {
            $0.attendeStatus == .tentative
        }

        if let firstAcceptedEvent = acceptedEvents.first {
            return firstAcceptedEvent
        }

        // If there are no accepted events, prefer the first optional event
        if acceptedEvents.isEmpty, !optionalEvents.isEmpty {
            return optionalEvents.first
        }

        // Otherwise check if there's a filtered event at all and return it
        if let first = filteredEvents.first {
            return first
        }

        let filteredAllDayEvent = relevantEvents.filter {
            $0.isAllDay
        }.first

        return filteredAllDayEvent
    }

    func upcomingEventsForDay(_: [EventInfo]) -> [EventInfo]? {
        if calendarAccessDenied() || calendarAccessNotDetermined() {
            return nil
        }

        let todayEvents = filteredEvents[autoupdatingCalendar.startOfDay(for: Date())] ?? []
        let tomorrowEvents = filteredEvents[autoupdatingCalendar.startOfDay(for: Date().addingTimeInterval(86400))] ?? []
        let relevantEvents = todayEvents + tomorrowEvents
        return relevantEvents.filter {
            $0.event.startDate.timeIntervalSinceNow > -300
        }
    }

    func initializeStoreIfNeccesary() {
        if eventStore == nil {
            eventStore = EKEventStore()
        }
    }

    func requestAccess(to entity: EKEntityType, completionHandler: @escaping (_ granted: Bool) -> Void) {
        initializeStoreIfNeccesary()

        eventStore.requestAccess(to: entity) { [weak self] granted, _ in

            // On successful granting of calendar permission, we default to showing events from all calendars
            if let self = self, entity == .event, granted {
                self.saveDefaultIdentifiersList()
            }

            completionHandler(granted)
        }
    }

    func filterEvents() {
        filteredEvents = [:]

        if let selectedCalendars = UserDefaults.standard.array(forKey: CLSelectedCalendars) as? [String] {
            for date in eventsForDate.keys {
                if let events = eventsForDate[date] {
                    for event in events {
                        if selectedCalendars.contains(event.event.calendar.calendarIdentifier) {
                            if filteredEvents[date] == nil {
                                filteredEvents[date] = Array()
                            }

                            filteredEvents[date]?.append(event)
                        }
                    }
                }
            }

            Logger.info("Fetched filtered events for \(filteredEvents.count) days\n")

            return
        }

        Logger.info("Unable to filter events because user hasn't selected calendars")
    }

    func saveDefaultIdentifiersList() {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            let allCalendars = self.retrieveAllCalendarIdentifiers()

            if !allCalendars.isEmpty {
                UserDefaults.standard.set(allCalendars, forKey: CLSelectedCalendars)
                Logger.info("Finished saving all calendar identifiers in default")
                self.filterEvents()
            }
        }
    }

    func retrieveAllCalendarIdentifiers() -> [String] {
        return eventStore.calendars(for: .event).map { calendar -> String in
            calendar.calendarIdentifier
        }
    }

    private func createDateComponents(with calendar: NSCalendar?, _ day: Int) -> Date {
        var dateComps = DateComponents()
        dateComps.day = day
        guard let convertedDate = calendar?.date(byAdding: dateComps,
                                                 to: Date(),
                                                 options: NSCalendar.Options.matchFirst)
        else {
            return Date()
        }
        return convertedDate
    }

    private func shouldSkipEvent(_ event: EKEvent) -> Bool {
        if event.hasAttendees, let attendes = event.attendees {
            for participant in attendes where participant.isCurrentUser && participant.participantStatus == .declined {
                return true
            }
        }

        return false
    }

    func fetchEvents(_ start: Int, _ end: Int) {
        if calendarAccessDenied() || calendarAccessNotDetermined() {
            Logger.info("Refetching aborted because we don't have permission!")
            return
        }

        initializeStoreIfNeccesary()

        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)

        let startDate = createDateComponents(with: calendar, start)
        let endDate = createDateComponents(with: calendar, end)

        // Passing in nil for calendars to search all calendars
        let predicate = eventStore.predicateForEvents(withStart: startDate,
                                                      end: endDate,
                                                      calendars: nil)

        var eventsForDateMapper: [Date: [EventInfo]] = [:]

        let events = eventStore.events(matching: predicate)

        // Populate our cache with events that match our startDate and endDate.
        // We map eachDate to array of events happening on that day

        for event in events where shouldSkipEvent(event) == false {
            // Iterate through the days this event spans. We only care about
            // days for this event that are between startDate and endDate
            let eventStartDate = event.startDate as NSDate
            let eventEndDate = event.endDate as NSDate

            var date = eventStartDate.laterDate(startDate)
            let final = eventEndDate.earlierDate(endDate)
            date = autoupdatingCalendar.startOfDay(for: date)

            while date.compare(final) == .orderedAscending {
                guard var nextDate = autoupdatingCalendar.date(byAdding: Calendar.Component.day, value: 1, to: date) else {
                    Logger.info("Could not calculate end date")
                    return
                }
                nextDate = autoupdatingCalendar.startOfDay(for: nextDate)

                if eventsForDateMapper[date] == nil {
                    eventsForDateMapper[date] = []
                }

                eventsForDateMapper[date]?.append(generateEventInfo(for: event, date, nextDate))

                date = nextDate
            }
        }

        // We now sort the array so that AllDay Events are first, then sort by startTime

        for date in eventsForDateMapper.keys {
            let sortedEvents = eventsForDateMapper[date]?.sorted(by: { event1, event2 -> Bool in
                if event1.isAllDay { return true } else if event2.isAllDay { return false } else { return event1.event.startDate < event2.event.startDate }
            })
            eventsForDateMapper[date] = sortedEvents
        }

        eventsForDate = eventsForDateMapper

        Logger.info("Fetched events for \(eventsForDate.count) days")

        filterEvents()
    }

    private func generateEventInfo(for event: EKEvent, _ date: Date, _ nextDate: Date) -> EventInfo {
        // Make a customized struct
        let isStartDate = autoupdatingCalendar.isDate(date, inSameDayAs: event.startDate) && (event.endDate.compare(date) == .orderedDescending)
        let isEndDate = autoupdatingCalendar.isDate(date, inSameDayAs: event.endDate) && (event.startDate.compare(date) == .orderedAscending)
        let isAllDay = event.isAllDay || (event.startDate.compare(date) == .orderedAscending && event.endDate.compare(nextDate) == .orderedSame)
        let isSingleDay = event.isAllDay && (event.startDate.compare(date) == .orderedSame && event.endDate.compare(nextDate) == .orderedSame)
        let eventParticipationStatus = attendingStatusForUser(event)
        let meetingURL = retrieveMeetingURL(event)
        let eventInfo = EventInfo(event: event,
                                  isStartDate: isStartDate,
                                  isEndDate: isEndDate,
                                  isAllDay: isAllDay,
                                  isSingleDay: isSingleDay,
                                  meetingURL: meetingURL,
                                  attendeStatus: eventParticipationStatus)
        return eventInfo
    }

    static var dataDetector: NSDataDetector?

    // Borrowing logic from Ityscal
    @discardableResult
    private func findAppropriateURLs(_ description: String) -> URL? {
        guard let results = EventCenter.dataDetector?.matches(in: description, options: .reportCompletion, range: NSRange(location: 0, length: description.count)) else {
            return nil
        }
        for result in results {
            if result.resultType == .link, var actualLink = result.url?.absoluteString {
                // Check for Zoom links
                if actualLink.contains("zoom.us/j/")
                    || actualLink.contains("zoom.us/s/")
                    || actualLink.contains("zoom.us/w/")
                {
                    // Create a Zoom App link
                    let workspace = NSWorkspace.shared
                    if workspace.urlForApplication(toOpen: URL(string: "zoommtg://")!) != nil {
                        actualLink = actualLink.replacingOccurrences(of: "https://", with: "zoommtg://")
                        actualLink = actualLink.replacingOccurrences(of: "?", with: "&")
                        actualLink = actualLink.replacingOccurrences(of: "/j/", with: "/join?confno=")
                        actualLink = actualLink.replacingOccurrences(of: "/s/", with: "/join?confno=")
                        actualLink = actualLink.replacingOccurrences(of: "/w/", with: "/join?confno=")
                        if let appLink = URL(string: actualLink) {
                            return appLink
                        }
                    }
                } else if actualLink.contains("zoommtg://")
                    || actualLink.contains("meet.google.com/")
                    || actualLink.contains("hangouts.google.com/")
                    || actualLink.contains("webex.com/")
                    || actualLink.contains("gotomeeting.com/join")
                    || actualLink.contains("ringcentral.com/j")
                    || actualLink.contains("bigbluebutton.org/gl")
                    || actualLink.contains("://bigbluebutton.")
                    || actualLink.contains("://bbb.")
                    || actualLink.contains("indigo.collocall.de")
                    || actualLink.contains("public.senfcall.de")
                    || actualLink.contains("youcanbook.me/zoom/")
                    || actualLink.contains("workplace.com/groupcall")
                    || actualLink.contains("bluejeans.com/")
                {
                    if let meetingLink = result.url {
                        return meetingLink
                    }
                }
            }
        }
        return nil
    }

    private func retrieveMeetingURL(_ event: EKEvent) -> URL? {
        if EventCenter.dataDetector == nil {
            var dataDetector: NSDataDetector?
            do {
                dataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            } catch {
                assertionFailure("Unable to create a link-type data detector")
                return nil
            }
            EventCenter.dataDetector = dataDetector
        }

        if let location = event.location {
            return findAppropriateURLs(location)
        }

        if let url = event.url {
            return findAppropriateURLs(url.absoluteString)
        }

        if let notes = event.notes {
            return findAppropriateURLs(notes)
        }

        return nil
    }

    private func attendingStatusForUser(_ event: EKEvent) -> EKParticipantStatus {
        // First check if the current user is the organizer
        if event.organizer?.isCurrentUser == true {
            return event.organizer?.participantStatus ?? .unknown
        }

        guard let attendes = event.attendees else {
            return .unknown
        }

        for attende in attendes where attende.isCurrentUser {
            return attende.participantStatus
        }

        return .unknown
    }
}

struct CalendarInfo {
    let calendar: EKCalendar
    var selected: Bool
}

struct EventInfo {
    let event: EKEvent
    let isStartDate: Bool
    let isEndDate: Bool
    let isAllDay: Bool
    let isSingleDay: Bool
    let meetingURL: URL?
    let attendeStatus: EKParticipantStatus

    func metadataForMeeting() -> String {
        let timeIntervalSinceNowForMeeting = event.startDate.timeIntervalSinceNow
        if timeIntervalSinceNowForMeeting < 0, timeIntervalSinceNowForMeeting > -300 {
            return "started +\(event.startDate.shortTimeAgoSinceNow)."
        } else if event.startDate.isToday {
            let timeSince = Date().timeAgo(since: event.startDate).lowercased()
            let withoutAn = timeSince.replacingOccurrences(of: "an", with: CLEmptyString)
            let withoutAgo = withoutAn.replacingOccurrences(of: "ago", with: CLEmptyString)
            // If the user has not turned on seconds granularity for one of the timezones,
            // we return "in 12 seconds" which looks weird.
            return withoutAgo.contains("seconds") ? "in <1m" : "in \(withoutAgo.lowercased())"
        } else if event.startDate.isTomorrow {
            let hoursUntil = event.startDate.hoursUntil
            return "in \(hoursUntil)h"
        }

        return "Error"
    }
}
