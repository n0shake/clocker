// Copyright © 2015 Abhishek Banthia

import CoreLoggerKit
import CoreModelKit
import Foundation

struct ConfigExport {
    private func generateJSON(from store: DataStore) {
        let selectedKeys: Set<String> = Set([
            CLShowOnboardingFlow,
            CLSelectedTimeZoneFormatKey,
            CLThemeKey,
            CLShowDayInMenu,
            CLShowDateInMenu,
            CLShowPlaceInMenu,
            CLShowLocalTimeInMenu,
            CLDisplayFutureSliderKey,
            CLStartAtLogin,
            CLShowAppInForeground,
            CLSunriseSunsetTime,
            CLUserFontSizePreference,
            CLShowUpcomingEventView,
            CLShowAllDayEventsInUpcomingView,
            CLShowMeetingInMenubar,
            CLTruncateTextLength,
            CLFutureSliderRange,
            CLSelectedCalendars,
            CLAppDisplayOptions,
            CLLongStatusBarWarningMessage,
            CLMenubarCompactMode,
            CLDefaultMenubarMode,
            CLInstallHomeIndicatorObject,
            CLSwitchToCompactModeAlert,
        ])
        let dictionaryRep = UserDefaults.standard.dictionaryRepresentation()
        var clockerPrefs: [String: Any] = [:]
        for (key, value) in dictionaryRep {
            if selectedKeys.contains(key) {
                Logger.info("Config Export: Key is \(key) and value is \(value)")
                clockerPrefs[key] = value
            }
        }

        do {
            let decodeJSON: [[String: Any]] = store.timezones().compactMap { data -> [String: Any]? in
                guard let customObject = TimezoneData.customObject(from: data) else { return nil }
                let timezoneDictionary: [String: Any] = [
                    "Name": customObject.formattedAddress ?? "",
                    "Custom": customObject.customLabel ?? "",
                    "TimezoneID": customObject.timezoneID ?? "N/A",
                    "Is System": customObject.isSystemTimezone ? 1 : 0,
                    "Is Favorite": customObject.isFavourite == 1 ? 1 : 0,
                    "Sunrise or Sunset": customObject.isSunriseOrSunset ? 1 : 0,
                    "Latitude": customObject.latitude ?? 0.0,
                    "Longitude": customObject.longitude ?? 0.0,
                    "Place Identifier": customObject.placeID ?? "0.0",
                    "Selection Type": "\(customObject.selectionType)",
                ]
                return timezoneDictionary
            }

            let timezoneDict = ["Timezones": decodeJSON]
            clockerPrefs.merge(timezoneDict) { current, _ in current }

            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileUrl = documentDirectoryUrl.appendingPathComponent("Persons.json")
            // Transform array into data and save it into file
            do {
                let data = try JSONSerialization.data(withJSONObject: clockerPrefs, options: [])
                try data.write(to: fileUrl, options: [])
            } catch {
                print(error)
            }

            let json = try JSONSerialization.data(withJSONObject: clockerPrefs, options: .prettyPrinted)
            print(json)
        } catch {
            Logger.info("Failure Observed \(error.localizedDescription)")
        }
    }
}
