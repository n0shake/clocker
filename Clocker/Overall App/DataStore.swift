// Copyright © 2015 Abhishek Banthia

import Cocoa

enum ViewType {
    case futureSlider
    case upcomingEventView
    case twelveHour
    case sunrise
    case seconds
    case showMeetingInMenubar
    case showAllDayEventsInMenubar
    case showAppInForeground
    case dateInMenubar
    case placeInMenubar
    case dayInMenubar
    case menubarCompactMode
}

class DataStore: NSObject {
    private static var sharedStore = DataStore(with: UserDefaults.standard)
    private var userDefaults: UserDefaults!
    
    // Since this pref can accessed every second, let's cache this
    private var shouldDisplayDateInMenubar: Bool = false

    @objc class func shared() -> DataStore {
        return sharedStore
    }

    init(with defaults: UserDefaults) {
        super.init()
        userDefaults = defaults
        shouldDisplayDateInMenubar = shouldDisplay(.dayInMenubar)
    }

    @objc func timezones() -> [Data] {
        guard let preferences = userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data] else {
            return []
        }

        return preferences
    }
    
    func updateDayPreference() {
        shouldDisplayDateInMenubar = shouldDisplay(.dayInMenubar)
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

    func shouldDisplay(_ type: ViewType) -> Bool {
        switch type {
        case .futureSlider:
            guard let value = retrieve(key: CLDisplayFutureSliderKey) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .upcomingEventView:
            guard let value = retrieve(key: CLShowUpcomingEventView) as? NSString else {
                return false
            }
            return value == "YES"

        case .twelveHour:

            guard let value = retrieve(key: CL24hourFormatSelectedKey) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .showAllDayEventsInMenubar:

            guard let value = retrieve(key: CLShowAllDayEventsInUpcomingView) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .sunrise:

            guard let value = retrieve(key: CLSunriseSunsetTime) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .seconds:

            guard let value = retrieve(key: CLShowSecondsInMenubar) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .showMeetingInMenubar:

            guard let value = retrieve(key: CLShowMeetingInMenubar) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .showAppInForeground:

            guard let value = retrieve(key: CLShowAppInForeground) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 1))

        case .dateInMenubar:

            guard let value = retrieve(key: CLShowDateInMenu) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .placeInMenubar:

            guard let value = retrieve(key: CLShowPlaceInMenu) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))

        case .dayInMenubar:

            guard let value = retrieve(key: CLShowDayInMenu) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 0))
            
        case .menubarCompactMode:
            
            guard let value = retrieve(key: CLMenubarCompactMode) as? Int else {
                return false
            }
            
            return value == 0
        }
    }
}
