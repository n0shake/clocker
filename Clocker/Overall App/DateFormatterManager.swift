// Copyright © 2015 Abhishek Banthia

import Cocoa

class DateFormatterManager: NSObject {

    private static var dateFormatter = DateFormatter()
    private static var calendarDateFormatter = DateFormatter()
    private static var simpleFormatter = DateFormatter()
    private static var specializedFormatter = DateFormatter()
    private static var localizedForamtter = DateFormatter()
    private static var localizedSimpleFormatter = DateFormatter()
    private static var gregorianCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
    private static var USLocale = Locale(identifier: "en_US")

    class func dateFormatter(with style: DateFormatter.Style, for timezoneIdentifier: String) -> DateFormatter {
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = style
        dateFormatter.locale = USLocale
        dateFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return dateFormatter
    }

    class func dateFormatterWithFormat(with style: DateFormatter.Style, format: String, timezoneIdentifier: String, locale: Locale = Locale(identifier: "en_US")) -> DateFormatter {
        specializedFormatter.dateStyle = style
        specializedFormatter.timeStyle = style
        specializedFormatter.dateFormat = format
        specializedFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        specializedFormatter.locale = locale
        return specializedFormatter
    }

    class func localizedFormatter(with format: String, for timezoneIdentifier: String, locale _: Locale = Locale.autoupdatingCurrent) -> DateFormatter {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.autoupdatingCurrent
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return dateFormatter
    }

    class func localizedSimpleFormatter(_ format: String) -> DateFormatter {
        localizedSimpleFormatter.dateStyle = .none
        localizedSimpleFormatter.timeStyle = .none
        localizedSimpleFormatter.dateFormat = format
        localizedSimpleFormatter.locale = Locale.autoupdatingCurrent
        return localizedSimpleFormatter
    }
}
