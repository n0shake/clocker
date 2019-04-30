// Copyright © 2015 Abhishek Banthia

import Cocoa

class DateFormatterManager: NSObject {
    public static let sharedInstance = DateFormatterManager()

    private static var dateFormatter: DateFormatter = DateFormatter()
    private static var calendarDateFormatter: DateFormatter = DateFormatter()
    private static var simpleFormatter: DateFormatter = DateFormatter()
    private static var specializedFormatter = DateFormatter()
    private static var localizedForamtter = DateFormatter()
    private static var localizedSimpleFormatter = DateFormatter()
    private static var gregorianCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
    private static var USLocale = Locale(identifier: "en_US")

    @objc class func dateFormatter(with style: DateFormatter.Style, for timezoneIdentifier: String) -> DateFormatter {
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = style
        dateFormatter.locale = USLocale
        dateFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return dateFormatter
    }

    @objc class func dateFormatterWithCalendar(with style: DateFormatter.Style) -> DateFormatter {
        calendarDateFormatter.dateStyle = style
        calendarDateFormatter.timeStyle = style
        calendarDateFormatter.locale = USLocale
        calendarDateFormatter.calendar = gregorianCalendar
        return calendarDateFormatter
    }

    @objc class func simpleFormatter(with style: DateFormatter.Style) -> DateFormatter {
        simpleFormatter.dateStyle = style
        simpleFormatter.timeStyle = style
        simpleFormatter.locale = USLocale
        return simpleFormatter
    }

    @objc class func dateFormatterWithFormat(with style: DateFormatter.Style, format: String, timezoneIdentifier: String, locale: Locale = Locale(identifier: "en_US")) -> DateFormatter {
        specializedFormatter.dateStyle = style
        specializedFormatter.timeStyle = style
        specializedFormatter.dateFormat = format
        specializedFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        specializedFormatter.locale = locale
        return specializedFormatter
    }
    
    @objc class func localizedFormatter(with format: String, for timezoneIdentifier: String, locale: Locale = Locale.autoupdatingCurrent) -> DateFormatter {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.autoupdatingCurrent
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        return dateFormatter
    }
    
    @objc class func localizedCalendaricalDateFormatter(with format: String) -> DateFormatter {
        calendarDateFormatter.dateStyle = .none
        calendarDateFormatter.timeStyle = .none
        calendarDateFormatter.locale = Locale.autoupdatingCurrent
        calendarDateFormatter.dateFormat = format
        calendarDateFormatter.calendar = gregorianCalendar
        return calendarDateFormatter
    }
    
    @objc class func localizedSimpleFormatter(_ format: String) -> DateFormatter {
        localizedSimpleFormatter.dateStyle = .none
        localizedSimpleFormatter.timeStyle = .none
        localizedSimpleFormatter.dateFormat = format
        localizedSimpleFormatter.locale = Locale.autoupdatingCurrent
        return localizedSimpleFormatter
    }
}
