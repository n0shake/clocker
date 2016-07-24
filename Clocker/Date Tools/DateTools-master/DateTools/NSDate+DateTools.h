// Copyright (C) 2014 by Matthew York
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and
// associated documentation files (the "Software"), to
// deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#ifndef DateToolsLocalizedStrings
#define DateToolsLocalizedStrings(key) \
NSLocalizedStringFromTableInBundle(key, @"DateTools", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[DTError class]] resourcePath] stringByAppendingPathComponent:@"DateTools.bundle"]], nil)
#endif

#import <Foundation/Foundation.h>
#import "DTConstants.h"

@interface NSDate (DateTools)

#pragma mark - Time Ago
+ (NSString*)timeAgoSinceDate:(NSDate*)date;
+ (NSString*)shortTimeAgoSinceDate:(NSDate*)date;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *timeAgoSinceNow;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *shortTimeAgoSinceNow;
- (NSString *)timeAgoSinceDate:(NSDate *)date;
- (NSString *)timeAgoSinceDate:(NSDate *)date numericDates:(BOOL)useNumericDates;
- (NSString *)timeAgoSinceDate:(NSDate *)date numericDates:(BOOL)useNumericDates numericTimes:(BOOL)useNumericTimes;
- (NSString *)shortTimeAgoSinceDate:(NSDate *)date;


#pragma mark - Date Components Without Calendar
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger era;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger year;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger month;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger day;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger hour;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger minute;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger second;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weekday;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weekdayOrdinal;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger quarter;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weekOfMonth;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weekOfYear;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger yearForWeekOfYear;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger daysInMonth;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger dayOfYear;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger daysInYear;
@property (NS_NONATOMIC_IOSONLY, getter=isInLeapYear, readonly) BOOL inLeapYear;
@property (NS_NONATOMIC_IOSONLY, getter=isToday, readonly) BOOL today;
@property (NS_NONATOMIC_IOSONLY, getter=isTomorrow, readonly) BOOL tomorrow;
@property (NS_NONATOMIC_IOSONLY, getter=isYesterday, readonly) BOOL yesterday;
@property (NS_NONATOMIC_IOSONLY, getter=isWeekend, readonly) BOOL weekend;
-(BOOL)isSameDay:(NSDate *)date;
+ (BOOL)isSameDay:(NSDate *)date asDate:(NSDate *)compareDate;

#pragma mark - Date Components With Calendar


- (NSInteger)eraWithCalendar:(NSCalendar *)calendar;
- (NSInteger)yearWithCalendar:(NSCalendar *)calendar;
- (NSInteger)monthWithCalendar:(NSCalendar *)calendar;
- (NSInteger)dayWithCalendar:(NSCalendar *)calendar;
- (NSInteger)hourWithCalendar:(NSCalendar *)calendar;
- (NSInteger)minuteWithCalendar:(NSCalendar *)calendar;
- (NSInteger)secondWithCalendar:(NSCalendar *)calendar;
- (NSInteger)weekdayWithCalendar:(NSCalendar *)calendar;
- (NSInteger)weekdayOrdinalWithCalendar:(NSCalendar *)calendar;
- (NSInteger)quarterWithCalendar:(NSCalendar *)calendar;
- (NSInteger)weekOfMonthWithCalendar:(NSCalendar *)calendar;
- (NSInteger)weekOfYearWithCalendar:(NSCalendar *)calendar;
- (NSInteger)yearForWeekOfYearWithCalendar:(NSCalendar *)calendar;


#pragma mark - Date Creating
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;
+ (NSDate *)dateWithString:(NSString *)dateString formatString:(NSString *)formatString;
+ (NSDate *)dateWithString:(NSString *)dateString formatString:(NSString *)formatString timeZone:(NSTimeZone *)timeZone;


#pragma mark - Date Editing
#pragma mark Date By Adding
- (NSDate *)dateByAddingYears:(NSInteger)years;
- (NSDate *)dateByAddingMonths:(NSInteger)months;
- (NSDate *)dateByAddingWeeks:(NSInteger)weeks;
- (NSDate *)dateByAddingDays:(NSInteger)days;
- (NSDate *)dateByAddingHours:(NSInteger)hours;
- (NSDate *)dateByAddingMinutes:(NSInteger)minutes;
- (NSDate *)dateByAddingSeconds:(NSInteger)seconds;
#pragma mark Date By Subtracting
- (NSDate *)dateBySubtractingYears:(NSInteger)years;
- (NSDate *)dateBySubtractingMonths:(NSInteger)months;
- (NSDate *)dateBySubtractingWeeks:(NSInteger)weeks;
- (NSDate *)dateBySubtractingDays:(NSInteger)days;
- (NSDate *)dateBySubtractingHours:(NSInteger)hours;
- (NSDate *)dateBySubtractingMinutes:(NSInteger)minutes;
- (NSDate *)dateBySubtractingSeconds:(NSInteger)seconds;

#pragma mark - Date Comparison
#pragma mark Time From
-(NSInteger)yearsFrom:(NSDate *)date;
-(NSInteger)monthsFrom:(NSDate *)date;
-(NSInteger)weeksFrom:(NSDate *)date;
-(NSInteger)daysFrom:(NSDate *)date;
-(double)hoursFrom:(NSDate *)date;
-(double)minutesFrom:(NSDate *)date;
-(double)secondsFrom:(NSDate *)date;
#pragma mark Time From With Calendar
-(NSInteger)yearsFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)monthsFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)weeksFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)daysFrom:(NSDate *)date calendar:(NSCalendar *)calendar;

#pragma mark Time Until
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger yearsUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger monthsUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weeksUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger daysUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) double hoursUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) double minutesUntil;
@property (NS_NONATOMIC_IOSONLY, readonly) double secondsUntil;
#pragma mark Time Ago
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger yearsAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger monthsAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger weeksAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger daysAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) double hoursAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) double minutesAgo;
@property (NS_NONATOMIC_IOSONLY, readonly) double secondsAgo;
#pragma mark Earlier Than
-(NSInteger)yearsEarlierThan:(NSDate *)date;
-(NSInteger)monthsEarlierThan:(NSDate *)date;
-(NSInteger)weeksEarlierThan:(NSDate *)date;
-(NSInteger)daysEarlierThan:(NSDate *)date;
-(double)hoursEarlierThan:(NSDate *)date;
-(double)minutesEarlierThan:(NSDate *)date;
-(double)secondsEarlierThan:(NSDate *)date;
#pragma mark Later Than
-(NSInteger)yearsLaterThan:(NSDate *)date;
-(NSInteger)monthsLaterThan:(NSDate *)date;
-(NSInteger)weeksLaterThan:(NSDate *)date;
-(NSInteger)daysLaterThan:(NSDate *)date;
-(double)hoursLaterThan:(NSDate *)date;
-(double)minutesLaterThan:(NSDate *)date;
-(double)secondsLaterThan:(NSDate *)date;
#pragma mark Comparators
-(BOOL)isEarlierThan:(NSDate *)date;
-(BOOL)isLaterThan:(NSDate *)date;
-(BOOL)isEarlierThanOrEqualTo:(NSDate *)date;
-(BOOL)isLaterThanOrEqualTo:(NSDate *)date;

#pragma mark - Formatted Dates
#pragma mark Formatted With Style
-(NSString *)formattedDateWithStyle:(NSDateFormatterStyle)style;
-(NSString *)formattedDateWithStyle:(NSDateFormatterStyle)style timeZone:(NSTimeZone *)timeZone;
-(NSString *)formattedDateWithStyle:(NSDateFormatterStyle)style locale:(NSLocale *)locale;
-(NSString *)formattedDateWithStyle:(NSDateFormatterStyle)style timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;
#pragma mark Formatted With Format
-(NSString *)formattedDateWithFormat:(NSString *)format;
-(NSString *)formattedDateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone;
-(NSString *)formattedDateWithFormat:(NSString *)format locale:(NSLocale *)locale;
-(NSString *)formattedDateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;

#pragma mark - Helpers
+(NSString *)defaultCalendarIdentifier;
+ (void)setDefaultCalendarIdentifier:(NSString *)identifier;
@end
