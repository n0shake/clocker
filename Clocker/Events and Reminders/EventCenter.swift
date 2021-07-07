// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import EventKit

class EventCenter: NSObject {
    private static var shared = EventCenter()

    var eventStore: EKEventStore!

    var calendar: EKCalendar?

    var autoupdatingCalendar = NSCalendar.autoupdatingCurrent

    var eventsForDate: [Date: [EventInfo]] = [:]

    var filteredEvents: [Date: [EventInfo]] = [:]

    private let fetchQueue = DispatchQueue(label: "com.abhishek.fetch")

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

    deinit {
        // Just to be super safe
        NotificationCenter.default.removeObserver(self)
    }

    private func refetchAll() {
        Logger.info("\nRefetching events from the store")

        eventsForDate = [:]
        filteredEvents = [:]
        autoreleasepool {
            fetchQueue.async {
                // We get events for a 120 day period.
                // If the user uses a calendar often, this will be called frequently
                self.fetchEvents(-40, 80)
            }
        }
    }
}
