// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

enum ViewType {
    case futureSlider
    case upcomingEventView
    case twelveHour
    case sunrise
    case showMeetingInMenubar
    case showAllDayEventsInMenubar
    case showAppInForeground
    case appDisplayOptions
    case dateInMenubar
    case placeInMenubar
    case dayInMenubar
    case menubarCompactMode
    case dstTransitionInfo
}

class DataStore: NSObject {
    private static var sharedStore = DataStore(with: UserDefaults.standard)
    private var userDefaults: UserDefaults!

    // Since these pref can accessed every second, let's cache this
    private var shouldDisplayDayInMenubar: Bool = false
    private var shouldDisplayDateInMenubar: Bool = false

    class func shared() -> DataStore {
        return sharedStore
    }

    init(with defaults: UserDefaults) {
        super.init()
        userDefaults = defaults
        shouldDisplayDayInMenubar = shouldDisplay(.dayInMenubar)
        shouldDisplayDateInMenubar = shouldDisplay(.dateInMenubar)
    }

    func timezones() -> [Data] {
        guard let preferences = userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data] else {
            return []
        }

        return preferences
    }

    func menubarTimezones() -> [Data]? {
        return timezones().filter {
            let customTimezone = TimezoneData.customObject(from: $0)
            return customTimezone?.isFavourite == 1
        }
    }

    func updateDayPreference() {
        shouldDisplayDayInMenubar = shouldDisplay(.dayInMenubar)
    }

    func updateDateInPreference() {
        shouldDisplayDateInMenubar = shouldDisplay(.dateInMenubar)
    }

    func shouldShowDayInMenubar() -> Bool {
        return shouldDisplayDayInMenubar
    }

    func shouldShowDateInMenubar() -> Bool {
        return shouldDisplayDateInMenubar
    }

    func setTimezones(_ timezones: [Data]) {
        userDefaults.set(timezones, forKey: CLDefaultPreferenceKey)
    }

    func retrieve(key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }

    func addTimezone(_ timezone: TimezoneData) {
        let encodedTimezone = NSKeyedArchiver.archivedData(withRootObject: timezone)

        var defaults: [Data] = (userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data]) ?? []
        defaults.append(encodedTimezone)

        userDefaults.set(defaults, forKey: CLDefaultPreferenceKey)
    }

    func removeLastTimezone() {
        var currentLineup = timezones()

        if currentLineup.isEmpty {
            return
        }

        currentLineup.removeLast()

        Logger.log(object: [:], for: "Undo Action Executed during Onboarding")

        userDefaults.set(currentLineup, forKey: CLDefaultPreferenceKey)
    }

    private func shouldDisplayHelper(_ key: String) -> Bool {
        guard let value = retrieve(key: key) as? NSNumber else {
            return false
        }
        return value.isEqual(to: NSNumber(value: 0))
    }

    func timezoneFormat() -> NSNumber {
        return userDefaults.object(forKey: CLSelectedTimeZoneFormatKey) as? NSNumber ?? NSNumber(integerLiteral: 0)
    }

    static let timeFormatsWithSuffix: Set<NSNumber> = Set([NSNumber(integerLiteral: 0),
                                                           NSNumber(integerLiteral: 3),
                                                           NSNumber(integerLiteral: 4),
                                                           NSNumber(integerLiteral: 6),
                                                           NSNumber(integerLiteral: 7)])

    func isBufferRequiredForTwelveHourFormats() -> Bool {
        return DataStore.timeFormatsWithSuffix.contains(timezoneFormat())
    }

    func shouldDisplay(_ type: ViewType) -> Bool {
        switch type {
        case .futureSlider:
            guard let value = retrieve(key: CLDisplayFutureSliderKey) as? NSNumber else {
                return false
            }
            return value != 2 // Modern is 0, Legacy is 1 and Hide is 2.
        case .upcomingEventView:
            guard let value = retrieve(key: CLShowUpcomingEventView) as? NSString else {
                return false
            }
            return value == "YES"
        case .twelveHour:
            return shouldDisplayHelper(CLSelectedTimeZoneFormatKey)
        case .showAllDayEventsInMenubar:
            return shouldDisplayHelper(CLShowAllDayEventsInUpcomingView)
        case .sunrise:
            return shouldDisplayHelper(CLSunriseSunsetTime)
        case .showMeetingInMenubar:
            return shouldDisplayHelper(CLShowMeetingInMenubar)
        case .showAppInForeground:
            guard let value = retrieve(key: CLShowAppInForeground) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 1))
        case .dateInMenubar:
            return shouldDisplayHelper(CLShowDateInMenu)
        case .placeInMenubar:
            return shouldDisplayHelper(CLShowPlaceInMenu)
        case .dayInMenubar:
            return shouldDisplayHelper(CLShowDayInMenu)
        case .appDisplayOptions:
            return shouldDisplayHelper(CLAppDisplayOptions)
        case .dstTransitionInfo:
            return shouldDisplayHelper(CLDisplayDSTTransitionInfo)
        case .menubarCompactMode:
            guard let value = retrieve(key: CLMenubarCompactMode) as? Int else {
                return false
            }

            return value == 0
        }
    }
}
