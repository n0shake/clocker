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

        let timezones = userDefaults.object(forKey: CLDefaultPreferenceKey)
        let selectedCalendars = userDefaults.object(forKey: CLSelectedCalendars)

        // Now delete the old preferences
        userDefaults.wipeIfNeccesary()

        // Register the usual suspects
        userDefaults.register(defaults: defaultsDictionary())

        userDefaults.set(timezones, forKey: CLDefaultPreferenceKey)
        userDefaults.set(selectedCalendars, forKey: CLSelectedCalendars)

        // Set the theme default as Light!
        setDefaultTheme()

        // If we already have timezones to display in menubar, do nothing.
        // Else, we switch the menubar mode default to compact mode for new users
        if userDefaults.bool(forKey: CLDefaultMenubarMode) == false {
            if let menubarFavourites = userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data], menubarFavourites.isEmpty == false {
                userDefaults.set(1, forKey: CLMenubarCompactMode)
            } else {
                userDefaults.set(0, forKey: CLMenubarCompactMode)
            }

            userDefaults.set(true, forKey: CLDefaultMenubarMode)
        }

        if userDefaults.bool(forKey: CLSwitchToCompactModeAlert) == false {
            userDefaults.set(true, forKey: CLSwitchToCompactModeAlert)

            if let menubarFavourites = DataStore.shared().menubarTimezones(), menubarFavourites.count > 1 {
                // If the user is already using the compact mode, abort.
                if DataStore.shared().shouldDisplay(.menubarCompactMode) {
                    return
                }

                showCompactModeAlert()
            }
        }
    }

    private class func setDefaultTheme() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: CLThemeKey) == nil {
            Themer.shared().set(theme: 0)
        }
    }

    private class func showCompactModeAlert() {
        // Time to display the alert.
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Save space on your menu bar"
        alert.informativeText = "Enable Menubar Compact Mode to fit in more timezones in less space!"
        alert.addButton(withTitle: "Enable Compact Mode")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response.rawValue == 1000 {
            OperationQueue.main.addOperation {
                UserDefaults.standard.set(0, forKey: CLMenubarCompactMode)

                guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
                    return
                }

                statusItem.setupStatusItem()

                Logger.log(object: ["Context": "On Launch"], for: "Switched to Compact Mode")
            }
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
                CLMenubarCompactMode: 1,
                CLDisplayDSTTransitionInfo: 0]
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
            removePersistentDomain(forName: bundleID)
            set(true, forKey: "PreferencesHaveBeenWiped")
        }
    }
}
