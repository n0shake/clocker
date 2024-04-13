//
//  Date+TimeAgo.swift
//  DateToolsTests
//
//  Created by Matthew York on 8/23/16.
//  Copyright © 2016 Matthew York. All rights reserved.
//

import Foundation

/**
 *  Extends the Date class by adding convenient methods to display the passage of
 *  time in String format.
 */
public extension Date {
    // MARK: - Time Ago

    /**
     *  Takes in a date and returns a string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - parameter date: Date to be measured from now
     *
     *  - returns String - Formatted return string
     */
    static func timeAgo(since date: Date) -> String {
        return date.timeAgo(since: Date(), numericDates: false, numericTimes: false)
    }

    /**
     *  Takes in a date and returns a shortened string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - parameter date: Date to be measured from now
     *
     *  - returns String - Formatted return string
     */
    static func shortTimeAgo(since date: Date) -> String {
        return date.shortTimeAgo(since: Date())
    }

    /**
     *  Returns a string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - returns String - Formatted return string
     */
    var timeAgoSinceNow: String {
        return timeAgo(since: Date())
    }

    /**
     *  Returns a shortened string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - returns String - Formatted return string
     */
    var shortTimeAgoSinceNow: String {
        return shortTimeAgo(since: Date())
    }

    func timeAgo(since date: Date, numericDates: Bool = false, numericTimes: Bool = false) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.second, .minute, .hour, .day, .weekOfYear, .month, .year])
        let earliest = earlierDate(date)
        let latest = (earliest == self) ? date : self // Should be triple equals, but not extended to Date at this time

        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        let yesterday = date.subtract(1.days)
        let isYesterday = yesterday.day == day

        // Not Yet Implemented/Optional
        // The following strings are present in the translation files but lack logic as of 2014.04.05
        // @"Today", @"This week", @"This month", @"This year"
        // and @"This morning", @"This afternoon"

        if components.year! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d %@years ago", value: components.year!)
        } else if components.year! >= 1 {
            if numericDates {
                return dateToolsLocalizedStrings("1 year ago")
            }

            return dateToolsLocalizedStrings("Last year")
        } else if components.month! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d %@months ago", value: components.month!)
        } else if components.month! >= 1 {
            if numericDates {
                return dateToolsLocalizedStrings("1 month ago")
            }

            return dateToolsLocalizedStrings("Last month")
        } else if components.weekOfYear! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d %@weeks ago", value: components.weekOfYear!)
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                return dateToolsLocalizedStrings("1 week ago")
            }

            return dateToolsLocalizedStrings("Last week")
        } else if components.day! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d %@days ago", value: components.day!)
        } else if isYesterday {
            if numericDates {
                return dateToolsLocalizedStrings("1 day ago")
            }

            return dateToolsLocalizedStrings("Yesterday")
        } else if components.hour! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d %@hours ago", value: components.hour!)
        } else if components.hour! >= 1 {
            if numericTimes {
                return dateToolsLocalizedStrings("1 hour ago")
            }

            return dateToolsLocalizedStrings("1h ago")
        } else if components.minute! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d%@m ago", value: components.minute!)
        } else if components.minute! >= 1 {
            if numericTimes {
                return dateToolsLocalizedStrings("1m ago")
            }

            return dateToolsLocalizedStrings("A minute ago")
        } else if components.second! >= 3 {
            return logicalLocalizedStringFromFormat(format: "%%d %@seconds ago", value: components.second!)
        } else {
            if numericTimes {
                return dateToolsLocalizedStrings("1 second ago")
            }

            // Instead of returning "Just now" or the equivalent localized version; let's return an empty string
            // Previously, we returned DateToolsLocalizedStrings("Just now")
            return UserDefaultKeys.emptyString
        }
    }

    func shortTimeAgo(since date: Date) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.second, .minute, .hour, .day, .weekOfYear, .month, .year])
        let earliest = earlierDate(date)
        let latest = (earliest == self) ? date : self // Should pbe triple equals, but not extended to Date at this time

        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        let yesterday = date.subtract(1.days)
        let isYesterday = yesterday.day == day

        if components.year! >= 1 {
            return logicalLocalizedStringFromFormat(format: "%%d%@y", value: components.year!)
        } else if components.month! >= 1 {
            return logicalLocalizedStringFromFormat(format: "%%d%@M", value: components.month!)
        } else if components.weekOfYear! >= 1 {
            return logicalLocalizedStringFromFormat(format: "%%d%@w", value: components.weekOfYear!)
        } else if components.day! >= 2 {
            return logicalLocalizedStringFromFormat(format: "%%d%@d", value: components.day!)
        } else if isYesterday {
            return logicalLocalizedStringFromFormat(format: "%%d%@d", value: 1)
        } else if components.hour! >= 1 {
            return logicalLocalizedStringFromFormat(format: "%%d%@h", value: components.hour!)
        } else if components.minute! >= 1 {
            return logicalLocalizedStringFromFormat(format: "%%d%@m", value: components.minute!)
        } else if components.second! >= 3 {
            return logicalLocalizedStringFromFormat(format: "%%d%@s", value: components.second!)
        } else {
            return logicalLocalizedStringFromFormat(format: "%%d%@s", value: components.second!)
            // return DateToolsLocalizedStrings(@"Now"); //string not yet translated 2014.04.05
        }
    }

    private func logicalLocalizedStringFromFormat(format: String, value: Int) -> String {
        let localeFormat = String(format: format, getLocaleFormatUnderscoresWithValue(Double(value)))
        return String(format: dateToolsLocalizedStrings(localeFormat), value)
    }

    private func getLocaleFormatUnderscoresWithValue(_ value: Double) -> String {
        let localCode = Bundle.main.preferredLocalizations[0]
        if localCode == "ru" || localCode == "uk" {
            let xy = Int(floor(value).truncatingRemainder(dividingBy: 100))
            let y = Int(floor(value).truncatingRemainder(dividingBy: 10))

            if y == 0 || y > 4 || (xy > 10 && xy < 15) {
                return ""
            }

            if y > 1, y < 5, xy < 10 || xy > 20 {
                return "_"
            }

            if y == 1, xy != 11 {
                return "__"
            }
        }

        return ""
    }

    // MARK: - Localization

    private func dateToolsLocalizedStrings(_ string: String) -> String {
        // let classBundle = Bundle(for:TimeChunk.self as! AnyClass.Type).resourcePath!.appending("DateTools.bundle")

        // let bundelPath = Bundle(path:classBundle)!
        #if os(Linux)
            // NSLocalizedString() is not available yet, see: https://github.com/apple/swift-corelibs-foundation/blob/16f83ddcd311b768e30a93637af161676b0a5f2f/Foundation/NSData.swift
            // However, a seemingly-equivalent method from NSBundle is: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/NSBundle.swift
            return Bundle.main.localizedString(forKey: string, value: "", table: "DateTools")
        #else
            return NSLocalizedString(string, tableName: "DateTools", bundle: Bundle.dateToolsBundle(), value: "", comment: "")
        #endif
    }

    // MARK: - Date Earlier/Later

    /**
     *  Return the earlier of two dates, between self and a given date.
     *
     *  - parameter date: The date to compare to self
     *
     *  - returns: The date that is earlier
     */
    func earlierDate(_ date: Date) -> Date {
        return (timeIntervalSince1970 <= date.timeIntervalSince1970) ? self : date
    }

    /**
     *  Return the later of two dates, between self and a given date.
     *
     *  - parameter date: The date to compare to self
     *
     *  - returns: The date that is later
     */
    func laterDate(_ date: Date) -> Date {
        return (timeIntervalSince1970 >= date.timeIntervalSince1970) ? self : date
    }
}
