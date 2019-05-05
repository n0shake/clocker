// Copyright © 2015 Abhishek Banthia

import EventKit

extension EventCenter {

    // MARK: Private helper methods

    private func retrieveCalendar() -> EKCalendar? {
        if calendar == nil {
            let calendars = store.calendars(for: .reminder)
            let calendarTitle = "Clocker Reminders"
            let predicate = NSPredicate(format: "title matches %@", calendarTitle)
            let filtered = calendars.filter({ predicate.evaluate(with: $0) })

            if !filtered.isEmpty {
                calendar = filtered.first
            } else {
                calendar = EKCalendar(for: .reminder, eventStore: store)
                calendar?.title = "Clocker Reminders"
                calendar?.source = store.defaultCalendarForNewReminders()?.source

                guard let calendar = calendar else { return nil }

                do {
                    try store.saveCalendar(calendar, commit: true)
                } catch {
                    assertionFailure("Unable to store calendar")
                }
            }
        }

        return calendar
    }

    // MARK: Public

    func reminderAccessGranted() -> Bool {
        return EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }

    func reminderAccessNotDetermined() -> Bool {
        return EKEventStore.authorizationStatus(for: .reminder) == .notDetermined
    }

    func reminderAccessDenied() -> Bool {
        return EKEventStore.authorizationStatus(for: .reminder) == .denied
    }

    func createReminder(with title: String,
                        timezone: String,
                        alertIndex: Int,
                        reminderDate: Date) -> Bool {
        if reminderAccessNotDetermined() || reminderAccessDenied() {
            return false
        }

        let gregorian = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let components: NSCalendar.Unit = [.day, .month, .year, .minute, .second, .hour]
        guard var reminderComponents: DateComponents = (gregorian?.components(components,
                                                                              from: reminderDate)) else { return false }
        reminderComponents.timeZone = TimeZone(identifier: timezone)

        let reminderEvent = EKReminder(eventStore: store)
        reminderEvent.calendar = retrieveCalendar()
        reminderEvent.title = "\(title) - Clocker"
        reminderEvent.startDateComponents = reminderComponents
        reminderEvent.dueDateComponents = reminderComponents

        addAlarmIfNeccesary(for: reminderEvent, alertIndex)

        // Commit the event
        do {
            try store.save(reminderEvent, commit: true)
        } catch {
            Logger.log(object: ["Error": error.localizedDescription],
                       for: "Error saving reminder")
            return false
        }

        return true
    }

    private func addAlarmIfNeccesary(for event: EKReminder, _ selection: Int) {
        if selection != 0 {
           var offset: TimeInterval = 0
            switch selection {
            case 2:
                offset = -300
            case 3:
                offset = -600
            case 4:
                offset = -900
            case 5:
                offset = -1800
            case 6:
                offset = -3600
            case 7:
                offset = -7200
            case 8:
                offset = -86400
            case 9:
                offset = -172_800
            default:
                offset = 0
            }
            let alarm = EKAlarm(relativeOffset: offset)
            event.addAlarm(alarm)
        }
    }
}
