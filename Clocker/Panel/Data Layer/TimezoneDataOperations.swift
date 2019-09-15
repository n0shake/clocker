// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLocation

class TimezoneDataOperations: NSObject {
    private var dataObject: TimezoneData!
    private lazy var nsCalendar: Calendar = Calendar.autoupdatingCurrent
    private static var gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
    private static var swiftyCalendar = Calendar(identifier: .gregorian)
    private static let currentLocale = Locale.current.identifier

    init(with timezone: TimezoneData) {
        dataObject = timezone
    }
}

extension TimezoneDataOperations {
    func time(with sliderValue: Int) -> String {
        guard let newDate = TimezoneDataOperations.gregorianCalendar?.date(byAdding: .minute,
                                                                           value: sliderValue,
                                                                           to: Date(),
                                                                           options: .matchFirst) else {
            assertionFailure("Data was unexpectedly nil")
            return CLEmptyString
        }

        let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                         format: dataObject.timezoneFormat(),
                                                                         timezoneIdentifier: dataObject.timezone(),
                                                                         locale: Locale.autoupdatingCurrent)

        return dateFormatter.string(from: newDate)
    }

    func compactMenuHeader() -> String {
        var subtitle = CLEmptyString

        let shouldDayBeShown = DataStore.shared().shouldShowDayInMenubar()

        if shouldDayBeShown {
            let substring = date(with: 0, displayType: CLDateDisplayType.menuDisplay)
            subtitle.append(substring)
        }

        let shouldDateBeShown = DataStore.shared().shouldShowDateInMenubar()
        if shouldDateBeShown {
            let date = Date().formatter(with: "MMM d", timeZone: dataObject.timezone())
            if subtitle.isEmpty == false {
                subtitle.append(" \(date)")
            } else {
                subtitle.append("\(date)")
            }
        }

        subtitle.isEmpty ? subtitle.append(time(with: 0)) : subtitle.append(" \(time(with: 0))")

        return subtitle
    }

    func menuTitle() -> String {
        var menuTitle = CLEmptyString

        let dataStore = DataStore.shared()

        let shouldCityBeShown = dataStore.shouldDisplay(.placeInMenubar)
        let shouldDayBeShown = dataStore.shouldShowDayInMenubar()
        let shouldDateBeShown = dataStore.shouldShowDateInMenubar()

        if shouldCityBeShown {
            if let address = dataObject.formattedAddress, address.isEmpty == false {
                if let label = dataObject.customLabel {
                    label.isEmpty == false ? menuTitle.append(label) : menuTitle.append(address)
                } else {
                    menuTitle.append(address)
                }

            } else {
                if let label = dataObject.customLabel {
                    label.isEmpty == false ? menuTitle.append(label) : menuTitle.append(dataObject.timezone())
                } else {
                    menuTitle.append(dataObject.timezone())
                }
            }
        }

        if shouldDayBeShown {
            var substring = date(with: 0, displayType: CLDateDisplayType.menuDisplay)
            let endIndex = substring.index(substring.startIndex, offsetBy: 2)
            substring = String(substring[substring.startIndex ... endIndex])

            if menuTitle.isEmpty == false {
                menuTitle.append(" \(substring.capitalized)")
            } else {
                menuTitle.append(substring.capitalized)
            }
        }

        if shouldDateBeShown {
            let date = Date().formatter(with: "MMM d", timeZone: dataObject.timezone())
            if menuTitle.isEmpty == false {
                menuTitle.append(" \(date)")
            } else {
                menuTitle.append("\(date)")
            }
        }

        menuTitle.isEmpty == false ? menuTitle.append(" \(time(with: 0))") : menuTitle.append(time(with: 0))

        return menuTitle
    }

    private func timezoneDate(with sliderValue: Int, _ calendar: Calendar) -> Date {
        let source = timezoneDateByAdding(minutesToAdd: sliderValue, calendar)
        let sourceTimezone = TimeZone.current
        let destinationTimezone = TimeZone(identifier: dataObject.timezone())

        let sourceGMTOffset: Double = Double(sourceTimezone.secondsFromGMT(for: source))
        let destinationGMTOffset: Double = Double(destinationTimezone?.secondsFromGMT(for: source) ?? 0)
        let interval = destinationGMTOffset - sourceGMTOffset

        return Date(timeInterval: interval, since: source)
    }

    // calendar.dateByAdding takes a 0.1% or 0.2% according to TimeProfiler
    // Let's not use it unless neccesary!
    private func timezoneDateByAdding(minutesToAdd: Int, _ calendar: Calendar?) -> Date {
        if minutesToAdd == 0 {
            return Date()
        }

        return calendar?.date(byAdding: .minute,
                              value: minutesToAdd,
                              to: Date()) ?? Date()
    }

    func date(with sliderValue: Int, displayType: CLDateDisplayType) -> String {
        var currentCalendar = Calendar(identifier: .gregorian)
        currentCalendar.locale = Locale.autoupdatingCurrent

        let convertedDate = timezoneDate(with: sliderValue, currentCalendar)

        guard let relativeDayPreference = DataStore.shared().retrieve(key: CLRelativeDateKey) as? NSNumber else {
            assertionFailure("Data was unexpectedly nil")
            return CLEmptyString
        }

        if displayType == CLDateDisplayType.panelDisplay {
            // Yesterday, tomorrow, etc
            if relativeDayPreference.intValue == 0 {
                let localFormatter = DateFormatterManager.localizedSimpleFormatter("EEEE")
                let local = localFormatter.date(from: localeDate(with: "EEEE"))

                // Gets local week day number and timezone's week day number for comparison
                let weekDay = currentCalendar.component(.weekday, from: local!)
                let timezoneWeekday = currentCalendar.component(.weekday, from: convertedDate)

                if weekDay == timezoneWeekday + 1 {
                    return "Yesterday\(timeDifference())"
                } else if weekDay == timezoneWeekday {
                    return "Today\(timeDifference())"
                } else if weekDay + 1 == timezoneWeekday || weekDay - 6 == timezoneWeekday {
                    return "Tomorrow\(timeDifference())"
                } else {
                    return "\(weekdayText(from: convertedDate))\(timeDifference())"
                }
            }

            // Day name: Thursday, Friday etc
            if relativeDayPreference.intValue == 1 {
                return "\(weekdayText(from: convertedDate))\(timeDifference())"
            }

            // Date in mmm/dd
            if relativeDayPreference.intValue == 2 {
                return "\(todaysDate(with: sliderValue))\(timeDifference())"
            }

            let errorDictionary: [String: Any] = ["Timezone": dataObject.timezone(),
                                                  "Current Locale": Locale.autoupdatingCurrent.identifier,
                                                  "Slider Value": sliderValue,
                                                  "Today's Date": Date()]
            Logger.log(object: errorDictionary, for: "Unable to get date")

            return "Error"

        } else {
            return "\(shortWeekdayText(convertedDate))"
        }
    }

    // Returns shortened weekday given a date
    // For eg. Thu or Thursday, Tues for Tuesday etc
    private func shortWeekdayText(_ date: Date) -> String {
        let localizedFormatter = DateFormatterManager.localizedSimpleFormatter("E")
        return localizedFormatter.string(from: date)
    }

    // Returns proper weekday given a date
    // For eg. Thursday, Sunday, Friday etc
    private func weekdayText(from date: Date) -> String {
        let dateFormatter = DateFormatterManager.localizedFormatter(with: "EEEE", for: TimeZone.current.identifier)
        return dateFormatter.string(from: date)
    }

    // Exposed to public for tests!
    public func timeDifference() -> String {
        let localFormatter = DateFormatterManager.localizedSimpleFormatter("d MMM yyyy HH:mm:ss")
        let local = localFormatter.date(from: localeDate(with: "d MMM yyyy HH:mm:ss"))!
        let newDate = timezoneDateByAdding(minutesToAdd: 0, TimezoneDataOperations.swiftyCalendar)

        let dateFormatter = DateFormatterManager.localizedFormatter(with: "d MMM yyyy HH:mm:ss", for: dataObject.timezone())

        guard let timezoneDate = localFormatter.date(from: dateFormatter.string(from: newDate)) else {
            let unableToConvertDateParameters = [
                "New Date": newDate,
                "Timezone": dataObject.timezone(),
                "Locale": dateFormatter.locale.identifier,
            ] as [String: Any]
            Logger.log(object: unableToConvertDateParameters, for: "Date conversion failure - New Date is nil")
            return CLEmptyString
        }

        let timeDifference = local.timeAgo(since: timezoneDate)

        if timeDifference.isEmpty {
            return CLEmptyString
        }

        if (local as NSDate).earlierDate(timezoneDate) == local {
            var replaceAgo = CLEmptyString
            replaceAgo.append(", ")
            let agoString = timezoneDate.timeAgo(since: local, numericDates: true)
            replaceAgo.append(agoString.replacingOccurrences(of: "ago", with: CLEmptyString))

            if !TimezoneDataOperations.currentLocale.contains("en") {
                return replaceAgo
            }

            let minuteDifference = calculateTimeDifference(with: local as NSDate, timezoneDate: timezoneDate as NSDate)
            minuteDifference == 0 ? replaceAgo.append("ahead") : replaceAgo.append("\(minuteDifference) mins ahead")
            return replaceAgo.lowercased()
        }

        var replaceAgo = CLEmptyString
        replaceAgo.append(", ")

        let replaced = timeDifference.replacingOccurrences(of: "ago", with: CLEmptyString)
        replaceAgo.append(replaced)

        let minuteDifference = calculateTimeDifference(with: local as NSDate, timezoneDate: timezoneDate as NSDate)

        minuteDifference == 0 ? replaceAgo.append("behind") : replaceAgo.append("\(minuteDifference) mins behind")
        return replaceAgo.lowercased()
    }

    private func initializeSunriseSunset(with sliderValue: Int) {
        let currentDate = nsCalendar.date(byAdding: .minute,
                                          value: sliderValue,
                                          to: Date())

        guard let lat = dataObject.latitude,
            let long = dataObject.longitude else {
            assertionFailure("Data was unexpectedly nil.")
            return
        }

        let coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)

        guard let dateForCalculation = currentDate, let solar = Solar(for: dateForCalculation, coordinate: coordinates) else {
            return
        }

        if let sunrise = solar.sunrise, let sunset = solar.sunset {
            dataObject.sunriseTime = sunrise
            dataObject.sunsetTime = sunset
            dataObject.isSunriseOrSunset = solar.isNighttime
        } else {
            Logger.log(object: ["Unable to fetch sunrise/sunset": dataObject.formattedTimezoneLabel()], for: "Sunrise/Sunset Error")
        }
    }

    private func calculateTimeDifference(with localDate: NSDate, timezoneDate: NSDate) -> Int {
        let earliest = localDate.earlierDate(timezoneDate as Date)
        let latest = earliest == localDate as Date ? timezoneDate : localDate

        // if timeAgo < 24h => compare DateTime else compare Date only
        let upToHours: Set<Calendar.Component> = [.second, .minute, .hour]
        let difference = nsCalendar.dateComponents(upToHours, from: earliest, to: latest as Date)
        return difference.minute!
    }

    func formattedSunriseTime(with sliderValue: Int) -> String {
        /* We have to call this everytime so that we get an updated value everytime! */

        if dataObject.selectionType == .timezone || (dataObject.latitude == nil || dataObject.longitude == nil) {
            return CLEmptyString
        }

        initializeSunriseSunset(with: sliderValue)

        if let sunrise = dataObject.sunriseTime, let sunset = dataObject.sunsetTime {
            let correct = dataObject.isSunriseOrSunset ? sunrise : sunset

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.timeZone = TimeZone(identifier: dataObject.timezone())
            dateFormatter.dateFormat = DataStore.shared().shouldDisplay(ViewType.twelveHour) ? "hh:mm a" : "HH:mm"
            return dateFormatter.string(from: correct)
        }

        return CLEmptyString
    }

    func todaysDate(with sliderValue: Int, locale: Locale = Locale(identifier: "en-US")) -> String {
        let newDate = TimezoneDataOperations.gregorianCalendar?.date(byAdding: .minute,
                                                                     value: sliderValue,
                                                                     to: Date(),
                                                                     options: .matchFirst)

        let date = newDate!.formatter(with: "MMM d", timeZone: dataObject.timezone(), locale: locale)

        return date
    }

    private func localDate() -> String {
        let dateFormatter = DateFormatterManager.dateFormatter(with: .medium, for: TimeZone.autoupdatingCurrent.identifier)
        return dateFormatter.string(from: Date())
    }

    private func localeDate(with format: String) -> String {
        let dateFormatter = DateFormatterManager.localizedFormatter(with: format, for: TimeZone.autoupdatingCurrent.identifier)
        return dateFormatter.string(from: Date())
    }

    func saveObject(at index: Int = -1) {
        var defaults = DataStore.shared().timezones()
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: dataObject as Any)
        index == -1 ? defaults.append(encodedObject) : defaults.insert(encodedObject, at: index)
        DataStore.shared().setTimezones(defaults)
    }
}

extension Date {
    func formatter(with format: String, timeZone: String, locale: Locale = Locale(identifier: "en-US")) -> String {
        let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .medium,
                                                                         format: format,
                                                                         timezoneIdentifier: timeZone,
                                                                         locale: locale)
        return dateFormatter.string(from: self)
    }
}
