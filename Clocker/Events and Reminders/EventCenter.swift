// Copyright © 2015 Abhishek Banthia

import Cocoa
import EventKit

class EventCenter: NSObject {
    private static var shared = EventCenter()

    let store = EKEventStore()

    var calendar: EKCalendar?

    var autoupdatingCalendar = NSCalendar.autoupdatingCurrent

    var eventsForDate: [Date: [EventInfo]] = [:]

    var filteredEvents: [Date: [EventInfo]] = [:]

    @discardableResult class func sharedCenter() -> EventCenter {
        return shared
    }

    override init() {
        super.init()
        refetchAll()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(EventCenter.eventStoreDidChange(_:)),
                                               name: .EKEventStoreChanged,
                                               object: nil)
    }

    @objc func eventStoreDidChange(_: Any) {
        refetchAll()
    }

    private func refetchAll() {
        print("\nRefetching events from the store")
        eventsForDate = [:]
        filteredEvents = [:]

        // We get events for a 120 day period.
        // If the user uses a calendar often, this will be called frequently
        fetchEvents(-40, 80)
    }
}
