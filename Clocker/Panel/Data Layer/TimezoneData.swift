// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

struct DateFormat {
    static let twelveHour = "h:mm a"
    static let twelveHourWithSeconds = "h:mm:ss a"
    static let twentyFourHour = "HH:mm"
    static let twentyFourHourWithSeconds = "HH:mm:ss"
    static let twelveHourWithZero = "hh:mm a"
    static let twelveHourWithZeroSeconds = "hh:mm:ss a"
    static let twelveHourWithoutSuffix = "hh:mm"
    static let twelveHourWithoutSuffixAndSeconds = "hh:mm:ss"
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
        case globalFormat = 0
        case twelveHourFormat = 1
        case twentyFourFormat = 2
        case twelveHourWithSeconds = 4
        case twentyHourWithSeconds = 5
        case twelveHourPrecedingZero = 7
        case twelveHourPrecedingZeroSeconds = 8
        case twelveHourWithoutSuffix = 10
        case twelveHourWithoutSuffixAndSeconds = 11
    }

    static let values = [
        NSNumber(integerLiteral: 0): DateFormat.twelveHour,
        NSNumber(integerLiteral: 1): DateFormat.twentyFourHour,

        // Seconds
        NSNumber(integerLiteral: 3): DateFormat.twelveHourWithSeconds,
        NSNumber(integerLiteral: 4): DateFormat.twentyFourHourWithSeconds,

        // Preceding Zero
        NSNumber(integerLiteral: 6): DateFormat.twelveHourWithZero,
        NSNumber(integerLiteral: 7): DateFormat.twelveHourWithZeroSeconds,

        // Suffix
        NSNumber(integerLiteral: 8): DateFormat.twelveHourWithoutSuffix,
        NSNumber(integerLiteral: 9): DateFormat.twelveHourWithoutSuffixAndSeconds,
    ]

    public var customLabel: String?
    public var formattedAddress: String?
    public var placeID: String?
    public var timezoneID: String? = CLEmptyString
    public var latitude: Double?
    public var longitude: Double?
    public var note: String? = CLEmptyString
    public var nextUpdate: Date? = Date()
    public var sunriseTime: Date?
    public var sunsetTime: Date?
    public var isFavourite: Int = 0
    public var isSunriseOrSunset = false
    public var selectionType: SelectionType = .city
    public var isSystemTimezone = false
    public var overrideFormat: TimezoneOverride = .globalFormat

    override init() {
        selectionType = .timezone
        isFavourite = 0
        note = CLEmptyString
        isSystemTimezone = false
        overrideFormat = .globalFormat
        placeID = UUID().uuidString
    }

    init(with dictionary: [String: Any]) {
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
    }

    class func customObject(from encodedData: Data?) -> TimezoneData? {
        guard let dataObject = encodedData else {
            return TimezoneData()
        }

        if let timezoneObject = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as? TimezoneData {
            return timezoneObject
        }

        return nil
    }

    /// Converts the Obj-C model objects into Swift
    class func convert() {
        if let timezones = DataStore.shared().retrieve(key: CLDefaultPreferenceKey) as? [Data], !timezones.isEmpty {
            let newModels = converter(timezones)

            if newModels.count == timezones.count {
                // Now point preferences to empty
                DataStore.shared().setTimezones([])

                // Now point it to new models
                DataStore.shared().setTimezones(newModels)
            }
        }
    }

    private class func converter(_ timezones: [Data]) -> [Data] {
        var newModels: [TimezoneData] = []

        for timezone in timezones {
            // Get the old (aka CLTimezoneData) model object
            let old = NSKeyedUnarchiver.unarchiveObject(with: timezone)
            if let newModel = old as? Clocker.TimezoneData {
                if UserDefaults.standard.object(forKey: "migrateOverrideFormat") == nil {
                    print("Resetting Global Format")
                    newModel.setShouldOverrideGlobalTimeFormat(0)
                }
                newModels.append(newModel)
            }
        }

        if UserDefaults.standard.object(forKey: "migrateOverrideFormat") == nil {
            UserDefaults.standard.set("YES", forKey: "migrateOverrideFormat")
        }

        // Do the serialization
        let serializedModels = newModels.map { (place) -> Data in
            NSKeyedArchiver.archivedData(withRootObject: place)
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
    }

    func formattedTimezoneLabel() -> String {
        // First check if there's an user preferred custom label set
        if let label = customLabel, !label.isEmpty {
            return label
        }

        // No custom label, return the formatted address/timezone
        if let address = formattedAddress, !address.isEmpty {
            return address
        }

        // No formatted address, return the timezoneID
        if let timezone = timezoneID, !timezone.isEmpty {
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
        customLabel = !label.isEmpty ? label : CLEmptyString
    }

    func setShouldOverrideGlobalTimeFormat(_ shouldOverride: Int) {
        if shouldOverride == 0 {
            overrideFormat = .globalFormat
        } else if shouldOverride == 1 {
            overrideFormat = .twelveHourFormat
        } else if shouldOverride == 2 {
            overrideFormat = .twentyFourFormat
        } else if shouldOverride == 4 {
            overrideFormat = .twelveHourWithSeconds
        } else if shouldOverride == 5 {
            print("Setting override format to five")
            overrideFormat = .twentyHourWithSeconds
        } else if shouldOverride == 7 {
            overrideFormat = .twelveHourPrecedingZero
        } else if shouldOverride == 8 {
            overrideFormat = .twelveHourPrecedingZeroSeconds
        } else if shouldOverride == 10 {
            overrideFormat = .twelveHourWithoutSuffix
        } else if shouldOverride == 11 {
            overrideFormat = .twelveHourWithoutSuffixAndSeconds
        } else {
            assertionFailure("Chosen a wrong timezone format")
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
        let chosenDefault = DataStore.shared().timezoneFormat()
        let timeFormat = TimezoneData.values[chosenDefault] ?? DateFormat.twelveHour

        if overrideFormat == .globalFormat {
            return timeFormat
        } else if overrideFormat == .twelveHourFormat {
            return DateFormat.twelveHour
        } else if overrideFormat == .twentyFourFormat {
            return DateFormat.twentyFourHour
        } else if overrideFormat == .twelveHourWithSeconds {
            return DateFormat.twelveHourWithSeconds
        } else if overrideFormat == .twentyHourWithSeconds {
            return DateFormat.twentyFourHourWithSeconds
        } else if overrideFormat == .twelveHourPrecedingZero {
            return DateFormat.twelveHourWithZero
        } else if overrideFormat == .twelveHourPrecedingZeroSeconds {
            return DateFormat.twelveHourWithZeroSeconds
        } else if overrideFormat == .twelveHourWithoutSuffix {
            return DateFormat.twelveHourWithoutSuffix
        } else if overrideFormat == .twelveHourWithoutSuffixAndSeconds {
            return DateFormat.twelveHourWithoutSuffixAndSeconds
        }

        return timeFormat
    }

    func shouldShowSeconds() -> Bool {
        if overrideFormat == .globalFormat {
            let currentFormat = DataStore.shared().timezoneFormat()
            let formatInString = TimezoneData.values[currentFormat] ?? DateFormat.twelveHour
            return formatInString.contains("ss")
        }

        let formatInString = TimezoneData.values[NSNumber(integerLiteral: overrideFormat.rawValue)] ?? DateFormat.twelveHour
        return formatInString.contains("ss")
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

    override func isEqual(to object: Any?) -> Bool {
        if let other = object as? TimezoneData {
            return placeID == other.placeID
        }
        return false
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let compared = object as? TimezoneData else {
            return false
        }

        // Plain timezones might have similar placeID. Adding another check for timezone identifier.
        return placeID == compared.placeID && timezoneID == compared.timezoneID
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
        """

        return customString
    }
}
