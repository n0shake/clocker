// Copyright © 2015 Abhishek Banthia

import Cocoa
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
        let calendars = store.calendars(for: .event).sorted { (cal1, cal2) -> Bool in

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

    func nextOccuring(_: [EventInfo]) -> EKEvent? {
        if calendarAccessDenied() || calendarAccessNotDetermined() {
            return nil
        }

        let relevantEvents = filteredEvents[autoupdatingCalendar.startOfDay(for: Date())] ?? []

        let filteredEvent = relevantEvents.filter({
            $0.event.isAllDay == false && $0.event.startDate.timeIntervalSinceNow > 0
        }).first

        if let firstEvent = filteredEvent {
            return firstEvent.event
        }

        let filteredAllDayEvent = relevantEvents.filter({
            $0.isAllDay
        }).first

        return filteredAllDayEvent?.event
    }

    func requestAccess(to entity: EKEntityType, completionHandler: @escaping (_ granted: Bool) -> Void) {
        store.requestAccess(to: entity) { [weak self] granted, _ in

            // On successful granting of calendar permission, we default to showing events from all calendars
            if let `self` = self, entity == .event, granted {
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
                                filteredEvents[date] = []
                            }

                            filteredEvents[date]?.append(event)
                        }
                    }
                }
            }

            print("Fetched filtered events for \(filteredEvents.count) days\n")

            return
        }

        print("Unable to filter events because user hasn't selected calendars")
    }

    func saveDefaultIdentifiersList() {
        OperationQueue.main.addOperation { [weak self] in
            guard let `self` = self else { return }
            let allCalendars = self.retrieveAllCalendarIdentifiers()

            if !allCalendars.isEmpty {
                UserDefaults.standard.set(allCalendars, forKey: CLSelectedCalendars)
                print("Finished saving all calendar identifiers in default")
                self.filterEvents()
            }
        }
    }

    func retrieveAllCalendarIdentifiers() -> [String] {
        return store.calendars(for: .event).map { (calendar) -> String in
            return calendar.calendarIdentifier
        }
    }

    func fetchEvents(_ start: Int, _ end: Int) {
        if calendarAccessDenied() || calendarAccessNotDetermined() {
            print("Refetching aborted because we don't have permission!")
            return
        }

        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)

        var startDateComponents = DateComponents()
        startDateComponents.day = start
        guard let startDate = calendar?.date(byAdding: startDateComponents,
                                             to: Date(),
                                             options: NSCalendar.Options.matchFirst) else {
            return
        }

        var endDateComponents = DateComponents()
        endDateComponents.day = end
        guard let endDate = calendar?.date(byAdding: endDateComponents,
                                           to: Date(),
                                           options: NSCalendar.Options.matchFirst) else {
            return
        }

        // Passing in nil for calendars to search all calendars
        let predicate = store.predicateForEvents(withStart: startDate,
                                                 end: endDate,
                                                 calendars: nil)

        var eventsForDateMapper: [Date: [EventInfo]] = [:]

        let events = store.events(matching: predicate)

        // Populate our cache with events that match our startDate and endDate.
        // We map eachDate to array of events happening on that day

        var skipEventBecauseUserDeclined = false

        for event in events {
            if event.hasAttendees, let attendes = event.attendees {
                for participant in attendes {
                    if participant.isCurrentUser && participant.participantStatus == .declined {
                        skipEventBecauseUserDeclined = true
                    }
                }
            }

            if skipEventBecauseUserDeclined { continue }

            // Iterate through the days this event spans. We only care about
            // days for this event that are between startDate and endDate

            let eventStartDate = event.startDate as NSDate
            let eventEndDate = event.endDate as NSDate

            var date = eventStartDate.laterDate(startDate)
            let final = eventEndDate.earlierDate(endDate)
            date = autoupdatingCalendar.startOfDay(for: date)

            while date.compare(final) == .orderedAscending {
                guard var nextDate = autoupdatingCalendar.date(byAdding: Calendar.Component.day, value: 1, to: date) else {
                    print("Could not calculate end date")
                    return
                }
                nextDate = autoupdatingCalendar.startOfDay(for: nextDate)

                // Make a customized struct
                let isStartDate = autoupdatingCalendar.isDate(date, inSameDayAs: event.startDate) && (event.endDate.compare(date) == .orderedDescending)
                let isEndDate = autoupdatingCalendar.isDate(date, inSameDayAs: event.endDate) && (event.startDate.compare(date) == .orderedAscending)
                let isAllDay = event.isAllDay || (event.startDate.compare(date) == .orderedAscending && event.endDate.compare(nextDate) == .orderedSame)
                let isSingleDay = event.isAllDay && (event.startDate.compare(date) == .orderedSame && event.endDate.compare(nextDate) == .orderedSame)

                let eventInfo = EventInfo(event: event,
                                          isStartDate: isStartDate,
                                          isEndDate: isEndDate,
                                          isAllDay: isAllDay,
                                          isSingleDay: isSingleDay)

                if eventsForDateMapper[date] == nil {
                    eventsForDateMapper[date] = []
                }

                eventsForDateMapper[date]?.append(eventInfo)

                date = nextDate
            }
        }

        // We now sort the array so that AllDay Events are first, then sort by startTime

        for date in eventsForDateMapper.keys {
            let sortedEvents = eventsForDateMapper[date]?.sorted(by: { (e1, e2) -> Bool in
                if e1.isAllDay { return true } else if e2.isAllDay { return false } else { return e1.event.startDate < e2.event.startDate }
            })
            eventsForDateMapper[date] = sortedEvents
        }

        eventsForDate = eventsForDateMapper

        print("Fetched events for \(eventsForDate.count) days")

        filterEvents()
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
}
