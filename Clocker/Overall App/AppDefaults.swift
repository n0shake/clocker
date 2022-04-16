// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class AppDefaults {
    class func initialize() {
        initializeDefaults()
    }

    private class func deleteOldUserDefaults() {
        let userDefaults = UserDefaults.standard

        // Now delete the old preferences
        if let bundleID = Bundle.main.bundleIdentifier, userDefaults.object(forKey: "PreferencesHaveBeenWiped") == nil {
            userDefaults.removePersistentDomain(forName: bundleID)
            userDefaults.set(true, forKey: "PreferencesHaveBeenWiped")
        }
    }

    private class func initializeDefaults() {
        let userDefaults = UserDefaults.standard
        let dataStore = DataStore.shared()

        let timezones = dataStore.timezones()
        let selectedCalendars = userDefaults.object(forKey: CLSelectedCalendars)

        // Now delete the old preferences
        userDefaults.wipeIfNeccesary()

        // Register the usual suspects
        userDefaults.register(defaults: defaultsDictionary())

        dataStore.setTimezones(timezones)
        userDefaults.set(selectedCalendars, forKey: CLSelectedCalendars)

        // Set the theme default as Light!
        setDefaultTheme()
    }

    private class func setDefaultTheme() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: CLThemeKey) == nil {
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
    func wipe() {
        if let bundleID = Bundle.main.bundleIdentifier {
            removePersistentDomain(forName: bundleID)
        }
    }

    func wipeIfNeccesary() {
        if let bundleID = Bundle.main.bundleIdentifier, object(forKey: "PreferencesHaveBeenWiped") == nil {
            Logger.info("Wiping all user defaults")
            removePersistentDomain(forName: bundleID)
            set(true, forKey: "PreferencesHaveBeenWiped")
        }
    }
}
