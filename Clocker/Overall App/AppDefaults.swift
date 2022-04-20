// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class AppDefaults {
    class func initialize(with store: DataStore, defaults: UserDefaults) {
        initializeDefaults(with: store, defaults: defaults)
    }

    private class func initializeDefaults(with store: DataStore, defaults: UserDefaults) {
        let timezones = store.timezones()
        let selectedCalendars = defaults.object(forKey: CLSelectedCalendars)

        // Register the usual suspects
        defaults.register(defaults: defaultsDictionary())

        store.setTimezones(timezones)
        defaults.set(selectedCalendars, forKey: CLSelectedCalendars)

        // Set the theme default as Light!
        setDefaultTheme(defaults)
    }

    private class func setDefaultTheme(_ userDefaults: UserDefaults) {
        if userDefaults.object(forKey: CLThemeKey) == nil {
            Themer.shared().set(theme: 0)
        }
    }

    private class func defaultsDictionary() -> [String: Any] {
        return [CLThemeKey: 0,
                CLDisplayFutureSliderKey: 0,
                CLSelectedTimeZoneFormatKey: 0, // 12-hour format
                CLRelativeDateKey: 0,
                CLShowDayInMenu: 0,
                CLShowDateInMenu: 1,
                CLShowPlaceInMenu: 0,
                CLStartAtLogin: 0,
                CLSunriseSunsetTime: 1,
                CLUserFontSizePreference: 4,
                CLShowUpcomingEventView: "YES",
                CLShowAppInForeground: 0,
                CLFutureSliderRange: 0,
                CLShowAllDayEventsInUpcomingView: 1,
                CLShowMeetingInMenubar: 1,
                CLTruncateTextLength: 30,
                CLSelectedCalendars: [],
                CLAppDisplayOptions: 0,
                CLMenubarCompactMode: 1]
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "Title for \(self)")
    }
}

extension UserDefaults {
    // Use this with caution. Exposing this for debugging purposes only.
    func wipe(for bundleID: String) {
        removePersistentDomain(forName: bundleID)
    }
}
