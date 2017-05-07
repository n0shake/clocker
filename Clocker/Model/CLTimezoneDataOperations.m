//
//  CLTimezoneDataOperations.m
//  Clocker
//
//  Created by Abhishek Banthia on 7/24/16.
//
//

#import "CLTimezoneDataOperations.h"
#import "CommonStrings.h"
#import "PanelController.h"
#import "DateTools.h"
#include "EDSunriseSet.h"
#import "CLAPIConnector.h"

@interface CLTimezoneDataOperations ()

@property (strong, nonatomic) CLTimezoneData *dataObject;

@end

@implementation CLTimezoneDataOperations

- (instancetype)initWithTimezoneData:(CLTimezoneData *)timezoneData
{
    self = [super init];
    
    if (self)
    {
        self.dataObject = timezoneData;
    }
    
    return self;
}

- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue
{
    NSCalendar *currentCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    
    NSNumber *showSeconds = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowSecondsInMenubar];
    
    if([showSeconds isEqualToNumber:@(0)])
    {
        dateFormatter.dateFormat = is24HourFormatSelected.boolValue ?  @"H:mm:ss" : @"h:mm:ss a";
    }
    else
    {
        dateFormatter.dateFormat = is24HourFormatSelected.boolValue ?  @"H:mm" : @"h:mm a";
    }
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.dataObject.timezoneID];
    //In the format 22:10
    
    return [dateFormatter stringFromDate:newDate];
}

- (NSString *)getMenuTitle
{
    NSMutableString *menuTitle = [NSMutableString new];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *shouldCityBeShown = [userDefaults objectForKey:CLShowPlaceInMenu];
    NSNumber *shouldDayBeShown = [userDefaults objectForKey:CLShowDayInMenu];
    NSNumber *shouldDateBeShown = [userDefaults objectForKey:CLShowDateInMenu];
    
    if (shouldCityBeShown.boolValue == 0)
    {
        
        if (self.dataObject.formattedAddress.length > 0) {
            self.dataObject.customLabel.length > 0 ?
            [menuTitle appendString:self.dataObject.customLabel] :
            [menuTitle appendString:self.dataObject.formattedAddress];
        }
        else
        {
            self.dataObject.customLabel.length > 0 ?
            [menuTitle appendString:self.dataObject.customLabel] :
            [menuTitle appendString:self.dataObject.timezoneID];
        }

        
    }
    
    if (shouldDayBeShown.boolValue == 0)
    {
        NSString *substring = [self getDateForTimeZoneWithFutureSliderValue:0 andDisplayType:CLMenuDisplay];
        
        substring = [substring substringToIndex:3];
        
        if (menuTitle.length > 0)
        {
            [menuTitle appendFormat:@" %@",substring.capitalizedString];
        }
        else
        {
            [menuTitle appendString:substring.capitalizedString];
        }
    }
    
    if (shouldDateBeShown.boolValue == 0)
    {
        NSString *date = [[NSDate date] formattedDateWithFormat:@"MMM d" timeZone:[NSTimeZone timeZoneWithName:self.dataObject.timezoneID] locale:[NSLocale currentLocale]];
        
        if (menuTitle.length > 0)
        {
            [menuTitle appendFormat:@" %@",date];
        }
        else
        {
            [menuTitle appendString:date];
        }
    }
    
    menuTitle.length > 0 ?
    [menuTitle appendFormat:@" %@",[self getTimeForTimeZoneWithFutureSliderValue:0]] :
    [menuTitle appendString:[self getTimeForTimeZoneWithFutureSliderValue:0]];
    
    return menuTitle;
}

- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue
                                       andDisplayType:(CLDateDisplayType)type
{
    NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    currentCalendar.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
    dateFormatter.timeStyle = kCFDateFormatterMediumStyle;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.dataObject.timezoneID];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSDate *convertedDate = [formatter dateFromString:[dateFormatter stringFromDate:newDate]];
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSInteger timezoneWeekday = [calendar component:NSCalendarUnitWeekday fromDate:convertedDate];
    timezoneWeekday = timezoneWeekday % 7;
    
    NSNumber *relativeDayPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    
    if (relativeDayPreference.integerValue == 0 && type == CLPanelDisplay)
    {
        NSDateFormatter *localFormatter = [NSDateFormatter new];
        localFormatter.timeStyle = NSDateFormatterMediumStyle;
        localFormatter.dateStyle = NSDateFormatterMediumStyle;
        localFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        
        NSDate *localDate = [localFormatter dateFromString:[self getLocalCurrentDate]];
        
        // Specify which units we would like to use
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:localDate];
        
        weekday = weekday % 7;
        
        if (weekday == timezoneWeekday + 1)
        {
            NSString *totalRelative = [NSString stringWithFormat:@"Yesterday%@", [self getTimeDifference]];
            return totalRelative;
        }
        else if (weekday == timezoneWeekday)
        {
            NSString *totalRelative = [NSString stringWithFormat:@"Today%@", [self getTimeDifference]];
            return totalRelative;
        }
        else if (weekday + 1 == timezoneWeekday)
        {
            NSString *totalRelative = [NSString stringWithFormat:@"Tomorrow%@", [self getTimeDifference]];
            return totalRelative;
        }
        else
        {
            NSString *totalRelative = [NSString stringWithFormat:@"%@%@", [self getWeekdayFromInteger:timezoneWeekday], [self getTimeDifference]];
            return totalRelative;
        }
        
    }
    else
    {
        NSString *totalRelative = [NSString stringWithFormat:@"%@%@", [self getWeekdayFromInteger:timezoneWeekday] , [self getTimeDifference]];
        return totalRelative;
    }
}

- (NSString *)getLocalCurrentDate
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
    dateFormatter.timeStyle = kCFDateFormatterMediumStyle;
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    return [dateFormatter stringFromDate:[NSDate date]];
    
}


- (NSString *)getWeekdayFromInteger:(NSInteger)weekdayInteger
{
    
    if (weekdayInteger > 7) {
        weekdayInteger = weekdayInteger - 7;
    }
    
    switch (weekdayInteger) {
        case 1:
            return @"Sunday";
            break;
            
        case 2:
            return @"Monday";
            break;
            
        case 3:
            return @"Tuesday";
            break;
            
        case 4:
            return @"Wednesday";
            break;
            
        case 5:
            return @"Thursday";
            break;
            
        case 6:
            return @"Friday";
            break;
            
        case 7:
            return @"Saturday";
            break;
            
        default:
            return @"Error";
            break;
    }
}

-(NSString *)getFormattedSunriseOrSunsetTimeAndSliderValue:(NSInteger)sliderValue
{
    /* We have to call this everytime so that we get an updated value everytime! */
    
    [self initializeSunriseSunsetWithSliderValue:sliderValue];
    
    if (!self.dataObject.sunriseTime && !self.dataObject.sunsetTime)
    {
        return CLEmptyString;
    }
    
    [self.dataObject setSunriseOrSunsetForTimezone:[self.dataObject.sunriseTime isLaterThanOrEqualTo:[NSDate date]]];
    
    NSDate *newDate = self.dataObject.sunriseOrSunset ? self.dataObject.sunriseTime : self.dataObject.sunsetTime;
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.dataObject.timezoneID];
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    
    dateFormatter.dateFormat = is24HourFormatSelected.boolValue ?  @"HH:mm" : @"hh:mm a";
    
    //In the format 22:10
    
    return [dateFormatter stringFromDate:newDate];
    
}

-(void)initializeSunriseSunsetWithSliderValue:(NSInteger)sliderValue
{
    
    if (!self.dataObject.latitude || !self.dataObject.longitude)
    {
        //Retrieve the values using Google Places API
        
        if (self.dataObject.selectionType == CLTimezoneSelection)
        {
            /* A timezone has been selected*/
            
            return;
        }
        
        [self retrieveLatitudeAndLongitudeWithSearchString:self.dataObject.formattedAddress];
        
    }
    
    EDSunriseSet *sunriseSetObject = [EDSunriseSet sunrisesetWithDate:[[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]
                                                                       dateByAddingUnit:NSCalendarUnitMinute
                                                                       value:sliderValue
                                                                       toDate:[NSDate date]
                                                                       options:kNilOptions]
                                                             timezone:[NSTimeZone timeZoneWithName:self.dataObject.timezoneID]
                                                             latitude:self.dataObject.latitude.doubleValue
                                                            longitude:self.dataObject.longitude.doubleValue];
    
    [self.dataObject setSunriseTimeForTimezone:sunriseSetObject.sunrise];
    [self.dataObject setSunsetTimeForTimezone:sunriseSetObject.sunset];
}


- (void)retrieveLatitudeAndLongitudeWithSearchString:(NSString *)formattedString
{
    NSString *preferredLanguage = [NSLocale preferredLanguages][0];
    
    if (![CLAPIConnector isUserConnectedToInternet])
    {
        /*Show some kind of information label*/
        return;
    }
    
    NSArray* words = [formattedString componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    formattedString = [words componentsJoinedByString:CLEmptyString];
    
    NSString *urlString = [NSString stringWithFormat:CLLocationSearchURL, formattedString, preferredLanguage];
    
    [CLAPIConnector dataTaskWithServicePath:urlString
                                   bySender:self
                        withCompletionBlock:^(NSError *error, NSDictionary *json) {
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                if (error || [json[@"status"] isEqualToString:@"ZERO_RESULTS"])
                                {
                                    return;
                                }
                                
                                
                                [json[@"results"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop)
                                 {
                                     
                                     if ([dictionary[CLPlaceIdentifier] isEqualToString:self.dataObject.place_id])
                                     {
                                         //We have a match
                                         
                                         NSDictionary *latLang = dictionary[@"geometry"][@"location"];
                                         
                                         [self.dataObject setLatitudeForTimezone:[NSString stringWithFormat:@"%@", latLang[@"lat"]]];
                                         [self.dataObject setLongitudeForTimezone:[NSString stringWithFormat:@"%@", latLang[@"lng"]]];
                                         
                                         
                                         
                                     }
                                     
                                 }];
                                
                            });
                            
                        }];
    
}

- (NSString *)getTimeDifference
{
    NSDateFormatter *localFormatter = [NSDateFormatter new];
    localFormatter.timeStyle = NSDateFormatterMediumStyle;
    localFormatter.dateStyle = NSDateFormatterMediumStyle;
    localFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:0
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.dataObject.timezoneID];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSDate *localDate = [localFormatter dateFromString:[self getLocalCurrentDate]];
    NSDate *timezoneDate = [localFormatter dateFromString:[dateFormatter stringFromDate:newDate]];
    

    if ([localDate isEarlierThan:timezoneDate])
    {
        NSMutableString *replaceAgo = [NSMutableString string];
        [replaceAgo appendString:@", "];
        [replaceAgo appendString:[[localDate timeAgoSinceDate:timezoneDate] stringByReplacingOccurrencesOfString:@"ago" withString:@"ahead"]];
        return replaceAgo;
    }
    
    NSMutableString *replaceAgo = [NSMutableString string];
    [replaceAgo appendString:@", "];
    NSString *timeDifference = [localDate timeAgoSinceDate:timezoneDate];
    
    if ([timeDifference containsString:@"Just now"])
    {
        return CLEmptyString;
    }
    
    [replaceAgo appendString:[timeDifference stringByReplacingOccurrencesOfString:@"ago" withString:@"behind"]];
    
    return replaceAgo;
}

- (void)save
{
    NSArray *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    
    if (defaultPreference == nil)
    {
        defaultPreference = [NSMutableArray new];
    }
    
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:self.dataObject];
    
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:defaultPreference];
    
    [newArray addObject:encodedObject];
    
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:CLDefaultPreferenceKey];
}



@end
