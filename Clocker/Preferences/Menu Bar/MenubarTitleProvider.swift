// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import EventKit

class MenubarTitleProvider: NSObject {
    private let store: DataStore
    
    init(with dataStore: DataStore) {
        self.store = dataStore
        super.init()
    }
    
    func titleForMenubar() -> String? {
        if let nextEvent = checkForUpcomingEvents() {
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
                let operationsObject = TimezoneDataOperations(with: timezone!)
                return "\(operationsObject.menuTitle().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))"
            }

            let titlesStringified = titles.compactMap { $0 }
            return titlesStringified.joined(separator: " ")
        }

        return nil
    }

    func checkForUpcomingEvents() -> String? {
        if store.shouldDisplay(.showMeetingInMenubar) {
            let filteredDates = EventCenter.sharedCenter().eventsForDate
            let autoupdatingCal = EventCenter.sharedCenter().autoupdatingCalendar
            guard let events = filteredDates[autoupdatingCal.startOfDay(for: Date())] else {
                return nil
            }

            for event in events {
                if event.event.startDate.timeIntervalSinceNow > 0, !event.isAllDay {
                    let timeForEventToStart = event.event.startDate.timeIntervalSinceNow / 60

                    if timeForEventToStart > 30 {
                        Logger.info("Our next event: \(event.event.title ?? "Error") starts in \(timeForEventToStart) mins")
                        continue
                    }

                    return EventCenter.sharedCenter().format(event: event.event)
                }
            }
        }

        return nil
    }
}
