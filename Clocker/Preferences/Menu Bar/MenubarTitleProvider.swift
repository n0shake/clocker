// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import EventKit

class MenubarTitleProvider: NSObject {
    private let store: DataStore
    private let eventCenter: EventCenter

    init(with dataStore: DataStore, eventStore: EventCenter) {
        store = dataStore
        eventCenter = eventStore
        super.init()
    }

    func titleForMenubar() -> String? {
        let filteredEvents = eventCenter.eventsForDate
        let autoupdatingCalendar = eventCenter.autoupdatingCalendar
        if let nextEvent = checkForUpcomingEvents(filteredEvents, calendar: autoupdatingCalendar) {
            return nextEvent
        }

        guard let menubarTitles = store.menubarTimezones() else {
            return nil
        }

        // If the menubar is in compact mode, we don't need any of the below calculations; exit early
        if store.shouldDisplay(.menubarCompactMode) {
            return nil
        }

        if menubarTitles.isEmpty == false {
            let titles = menubarTitles.map { data -> String? in
                let timezone = TimezoneData.customObject(from: data)
                let operationsObject = TimezoneDataOperations(with: timezone!, store: store)
                return "\(operationsObject.menuTitle().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))"
            }

            let titlesStringified = titles.compactMap { $0 }
            return titlesStringified.joined(separator: " ")
        }

        return nil
    }

    func checkForUpcomingEvents(_ filteredEvents: [Date: [EventInfo]], calendar: Calendar) -> String? {
        if store.shouldDisplay(.showMeetingInMenubar) {
            guard let events = filteredEvents[calendar.startOfDay(for: Date())] else {
                return nil
            }

            for eventInfo in events {
                let event = eventInfo.event
                let acceptableCriteria = event.startDate.timeIntervalSinceNow > -300
                if acceptableCriteria, !eventInfo.isAllDay {
                    let timeForEventToStart = event.startDate.timeIntervalSinceNow / 60

                    if timeForEventToStart > 30 {
                        Logger.info("Our next event: \(event.title ?? "Error") starts in \(timeForEventToStart) mins")
                        continue
                    }

                    return format(event: event)
                }
            }
        }

        return nil
    }

    internal func format(event: EKEvent) -> String {
        guard let truncateLength = store.retrieve(key: CLTruncateTextLength) as? NSNumber, let eventTitle = event.title, event.title.isEmpty == false else {
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
        if minutes >= 1 {
            let suffix = String(format: " in %0.fm", minutes)
            menubarText.append(suffix)
        } else {
            menubarText.append(" starts now.")
        }

        return menubarText
    }
}
