// Copyright © 2015 Abhishek Banthia

import Cocoa
import os.log

struct DateFormat {
    static let twelveHour = "h:mm a"
    static let twelveHourWithSeconds = "h:mm:ss a"
    static let twentyFourHour = "HH:mm"
    static let twentyFourHourWithSeconds = "HH:mm:ss"
}

// Non-class type cannot conform to NSCoding!
class TimezoneData: NSObject, NSCoding {
    
    enum SelectionType: Int {
        case city
        case timezone
    }

    enum DateDisplayType: Int {
        case panel
        case menu
    }

    enum TimezoneOverride: Int {
        case twelveHourFormat
        case twentyFourFormat
        case globalFormat
    }
    
    enum SecondsOverride: Int {
        case yes
        case no
        case globalFormat
    }

    var customLabel: String?
    var formattedAddress: String?
    var placeID: String?
    var timezoneID: String? = CLEmptyString
    var latitude: Double?
    var longitude: Double?
    var note: String? = CLEmptyString
    var nextUpdate: Date? = Date()
    var sunriseTime: Date?
    var sunsetTime: Date?
    var isFavourite: Int = 0
    var isSunriseOrSunset = false
    var selectionType: SelectionType = .city
    var isSystemTimezone = false
    var overrideFormat: TimezoneOverride = .globalFormat
    var overrideSecondsFormat: SecondsOverride = .globalFormat

    override init() {
        selectionType = .timezone
        isFavourite = 0
        note = CLEmptyString
        isSystemTimezone = false
        overrideFormat = .globalFormat
        overrideSecondsFormat = .globalFormat
    }

    init(with originalTimezone: CLTimezoneData) {
        customLabel = originalTimezone.customLabel
        formattedAddress = originalTimezone.formattedAddress
        placeID = originalTimezone.place_id
        timezoneID = originalTimezone.timezoneID

        if originalTimezone.latitude != nil {
            latitude = originalTimezone.latitude.doubleValue
        }

        if originalTimezone.longitude != nil {
            longitude = originalTimezone.longitude.doubleValue
        }

        note = originalTimezone.note
        nextUpdate = originalTimezone.nextUpdate
        sunriseTime = originalTimezone.sunriseTime
        sunsetTime = originalTimezone.sunsetTime
        isFavourite = originalTimezone.isFavourite.intValue
        isSunriseOrSunset = originalTimezone.sunriseOrSunset
        selectionType = originalTimezone.selectionType == CLSelection.citySelection ? .city : .timezone
        isSystemTimezone = originalTimezone.isSystemTimezone
        overrideFormat = .globalFormat
        overrideSecondsFormat = .globalFormat
    }

    init(with dictionary: Dictionary<String, Any>) {
        if let label = dictionary[CLCustomLabel] as? String {
            customLabel = label
        } else {
            customLabel = nil
        }

        if let timezone = dictionary[CLTimezoneID] as? String {
            timezoneID = timezone
        } else {
            timezoneID = "Error"
        }

        if let lat = dictionary["latitude"] as? Double {
            latitude = lat
        } else {
            latitude = -0.0
        }

        if let long = dictionary["longitude"] as? Double {
            longitude = long
        } else {
            longitude = -0.0
        }

        if let placeIdentifier = dictionary[CLPlaceIdentifier] as? String {
            placeID = placeIdentifier
        } else {
            placeID = "Error"
        }

        if let address = dictionary[CLTimezoneName] as? String {
            formattedAddress = address
        } else {
            formattedAddress = "Error"
        }

        isFavourite = 0

        selectionType = .city

        if let noteString = dictionary["note"] as? String {
            note = noteString
        } else {
            note = CLEmptyString
        }

        isSystemTimezone = false

        overrideFormat = .globalFormat
        overrideSecondsFormat = .globalFormat
    }

    required init?(coder aDecoder: NSCoder) {
        customLabel = aDecoder.decodeObject(forKey: "customLabel") as? String

        formattedAddress = aDecoder.decodeObject(forKey: "formattedAddress") as? String

        placeID = aDecoder.decodeObject(forKey: "place_id") as? String

        timezoneID = aDecoder.decodeObject(forKey: "timezoneID") as? String

        latitude = aDecoder.decodeObject(forKey: "latitude") as? Double

        longitude = aDecoder.decodeObject(forKey: "longitude") as? Double

        note = aDecoder.decodeObject(forKey: "note") as? String

        nextUpdate = aDecoder.decodeObject(forKey: "nextUpdate") as? Date

        sunriseTime = aDecoder.decodeObject(forKey: "sunriseTime") as? Date

        sunsetTime = aDecoder.decodeObject(forKey: "sunsetTime") as? Date

        isFavourite = aDecoder.decodeInteger(forKey: "isFavourite")

        let selection = aDecoder.decodeInteger(forKey: "selectionType")
        selectionType = SelectionType(rawValue: selection)!

        isSystemTimezone = aDecoder.decodeBool(forKey: "isSystemTimezone")

        let override = aDecoder.decodeInteger(forKey: "overrideFormat")
        overrideFormat = TimezoneOverride(rawValue: override)!
        
        let secondsOverride = aDecoder.decodeInteger(forKey: "secondsOverrideFormat")
        overrideSecondsFormat = SecondsOverride(rawValue: secondsOverride)!
    }

    class func customObject(from encodedData: Data?) -> TimezoneData? {
        guard let dataObject = encodedData else {
            return TimezoneData()
        }

        if let timezoneObject = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as? TimezoneData {
            return timezoneObject
        } else if let originalTimezoneObject = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as? CLTimezoneData {
            logOldModelUsage()
            return TimezoneData(with: originalTimezoneObject)
        }

        return nil
    }
    
    private class func logOldModelUsage() {
        guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
                return
        }
        
        let operatingSystem = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(operatingSystem.majorVersion).\(operatingSystem.minorVersion).\(operatingSystem.patchVersion)"
        let versionInfo = "Clocker \(shortVersion) (\(appVersion))"
        
        let feedbackInfo = [
            AppFeedbackConstants.CLOperatingSystemVersion: osVersion,
            AppFeedbackConstants.CLClockerVersion: versionInfo,
        ]

        Logger.log(object: feedbackInfo, for: "CLTimezoneData is still being used!")
    }

    /// Converts the Obj-C model objects into Swift
    class func convert() {
        if let timezones = DataStore.shared().retrieve(key: CLDefaultPreferenceKey) as? [Data], timezones.count > 0 {
            let newModels = converter(timezones)

            if newModels.count == timezones.count {
                // Now point preferences to empty
                DataStore.shared().setTimezones([])

                // Now point it to new models
                DataStore.shared().setTimezones(newModels)

                print("Successfully converted: \(newModels.count) timezones")
            }
        }

        if let menubarTimezones = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data], menubarTimezones.count > 0 {
            let newMenubarModels = converter(menubarTimezones)

            if newMenubarModels.count == menubarTimezones.count {
                // Now point preferences to empty
                UserDefaults.standard.set(nil, forKey: CLMenubarFavorites)

                // Now point it to new models
                UserDefaults.standard.set(newMenubarModels, forKey: CLMenubarFavorites)

                print("Successfully converted: \(newMenubarModels.count) menubar objects.")
            }
        }
    }

    private class func converter(_ timezones: [Data]) -> [Data] {
        var newModels: [TimezoneData] = []

        for timezone in timezones {
            // Get the old (aka CLTimezoneData) model object
            let old = NSKeyedUnarchiver.unarchiveObject(with: timezone)
            if let oldModel = old as? CLTimezoneData {
                // Convert it to new model and add it
                let newTimezone = TimezoneData(with: oldModel)
                newModels.append(newTimezone)
            } else if let newModel = old as? TimezoneData {
                newModels.append(newModel)
            }
        }

        // Do the serialization
        let serializedModels = newModels.map { (place) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: place)
        }

        return serializedModels
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(placeID, forKey: "place_id")

        aCoder.encode(formattedAddress, forKey: "formattedAddress")

        aCoder.encode(customLabel, forKey: "customLabel")

        aCoder.encode(timezoneID, forKey: "timezoneID")

        aCoder.encode(nextUpdate, forKey: "nextUpdate")

        aCoder.encode(latitude, forKey: "latitude")

        aCoder.encode(longitude, forKey: "longitude")

        aCoder.encode(isFavourite, forKey: "isFavourite")

        aCoder.encode(sunriseTime, forKey: "sunriseTime")

        aCoder.encode(sunsetTime, forKey: "sunsetTime")

        aCoder.encode(selectionType.rawValue, forKey: "selectionType")

        aCoder.encode(note, forKey: "note")

        aCoder.encode(isSystemTimezone, forKey: "isSystemTimezone")

        aCoder.encode(overrideFormat.rawValue, forKey: "overrideFormat")
        
        aCoder.encode(overrideSecondsFormat.rawValue, forKey: "secondsOverrideFormat")
    }

    func formattedTimezoneLabel() -> String {
        // First check if there's an user preferred custom label set
        if let label = customLabel, label.count > 0 {
            return label
        }

        // No custom label, return the formatted address/timezone
        if let address = formattedAddress, address.count > 0 {
            return address
        }

        // No formatted address, return the timezoneID
        if let timezone = timezoneID, timezone.count > 0 {
            let hashSeperatedString = timezone.components(separatedBy: "/")

            // Return the second component!
            if let first = hashSeperatedString.first {
                return first
            }

            // Second component not available, return the whole thing!
            return timezone
        }

        // Return error
        return "Error"
    }

    func setLabel(_ label: String) {
        customLabel = label.count > 0 ? label : CLEmptyString
    }

    func setShouldOverrideGlobalTimeFormat(_ shouldOverride: Int) {
        if shouldOverride == 0 {
            overrideFormat = .twelveHourFormat
        } else if shouldOverride == 1 {
            overrideFormat = .twentyFourFormat
        } else {
            overrideFormat = .globalFormat
        }
    }
    
    func setShouldOverrideSecondsFormat(_ shouldOverride: Int) {
        if shouldOverride == 0 {
            overrideSecondsFormat = .yes
        } else if shouldOverride == 1 {
            overrideSecondsFormat = .no
        } else {
            overrideSecondsFormat = .globalFormat
        }
    }

    func timezone() -> String {
        if isSystemTimezone {
            timezoneID = TimeZone.autoupdatingCurrent.identifier
            formattedAddress = TimeZone.autoupdatingCurrent.identifier
            return TimeZone.autoupdatingCurrent.identifier
        }

        if let timezone = timezoneID {
            return timezone
        }

        if let name = formattedAddress, let placeIdentifier = placeID, let timezoneIdentifier = timezoneID {
            let errorDictionary = [
                "Formatted Address": name,
                "Place Identifier": placeIdentifier,
                "TimezoneID": timezoneIdentifier,
            ]

            Logger.log(object: errorDictionary, for: "Error fetching timezone() in TimezoneData")
        }

        return TimeZone.autoupdatingCurrent.identifier
    }

    func timezoneFormat() -> String {
        let showSeconds = shouldShowSeconds()
        let isTwelveHourFormatSelected = DataStore.shared().shouldDisplay(.twelveHour)

        var timeFormat = DateFormat.twentyFourHour

        if showSeconds {
            if overrideFormat == .globalFormat {
                timeFormat = isTwelveHourFormatSelected ? DateFormat.twelveHourWithSeconds : DateFormat.twentyFourHourWithSeconds
            } else if overrideFormat == .twelveHourFormat {
                timeFormat = DateFormat.twelveHourWithSeconds
            } else {
                timeFormat = DateFormat.twentyFourHourWithSeconds
            }
        } else {
            if overrideFormat == .globalFormat {
                timeFormat = isTwelveHourFormatSelected ? DateFormat.twelveHour : DateFormat.twentyFourHour
            } else if overrideFormat == .twelveHourFormat {
                timeFormat = DateFormat.twelveHour
            } else {
                timeFormat = DateFormat.twentyFourHour
            }
        }

        return timeFormat
    }
    
    func shouldDisplayTwelveHourFormat() -> Bool {
        if overrideSecondsFormat == .globalFormat {
            return DataStore.shared().shouldDisplay(.twelveHour)
        }
        
        return overrideFormat == .twelveHourFormat
    }
    
    func shouldShowSeconds() -> Bool {
        if overrideSecondsFormat == .globalFormat {
            return DataStore.shared().shouldDisplay(.seconds)
        }

        return overrideSecondsFormat == .yes
    }

    override var hash: Int {
        guard let placeIdentifier = placeID, let timezone = timezoneID else {
            return -1
        }

        return placeIdentifier.hashValue ^ timezone.hashValue
    }

    static func == (lhs: TimezoneData, rhs: TimezoneData) -> Bool {
        return lhs.placeID == rhs.placeID
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let compared = object as? TimezoneData else {
            return false
        }
        return placeID == compared.placeID
    }
}

extension TimezoneData {
    private func adjustStatusBarAppearance() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.setupStatusItem()
    }
}

extension TimezoneData {
    override var description: String {
        return objectDescription()
    }

    override var debugDescription: String {
        return objectDescription()
    }

    private func objectDescription() -> String {
        let customString = """
        TimezoneID: \(timezoneID ?? "Error")
        Formatted Address: \(formattedAddress ?? "Error")
        Custom Label: \(customLabel ?? "Error")
        Latitude: \(latitude ?? -0.0)
        Longitude: \(longitude ?? -0.0)
        Place Identifier: \(placeID ?? "Error")
        Is Favourite: \(isFavourite)
        Sunrise Time: \(sunriseTime?.debugDescription ?? "N/A")
        Sunset Time: \(sunsetTime?.debugDescription ?? "N/A")
        Selection Type: \(selectionType.rawValue)
        Note: \(note ?? "Error")
        Is System Timezone: \(isSystemTimezone)
        Override: \(overrideFormat)
        Seconds Override: \(overrideSecondsFormat)
        """

        return customString
    }
}
