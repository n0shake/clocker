//
//  Constants.swift
//  DateTools
//
//  Created by Grayson Webster on 8/17/16.
//  Copyright © 2016 Grayson Webster. All rights reserved.
//

import Foundation

/**
 *  Time conversions used across DateTools
 */
public class Constants {
    public static let SecondsInYear: TimeInterval = 31_536_000
    public static let SecondsInLeapYear: TimeInterval = 31_622_400
    public static let SecondsInMonth28: TimeInterval = 2_419_200
    public static let SecondsInMonth29: TimeInterval = 2_505_600
    public static let SecondsInMonth30: TimeInterval = 2_592_000
    public static let SecondsInMonth31: TimeInterval = 2_678_400
    public static let SecondsInWeek: TimeInterval = 604_800
    public static let SecondsInDay: TimeInterval = 86400
    public static let SecondsInHour: TimeInterval = 3600
    public static let SecondsInMinute: TimeInterval = 60
    public static let MillisecondsInDay: TimeInterval = 86_400_000

    public static let AllCalendarUnitFlags: Set<Calendar.Component> = [.year, .quarter, .month, .weekOfYear, .weekOfMonth, .day, .hour, .minute, .second, .era, .weekday, .weekdayOrdinal, .weekOfYear]
}
