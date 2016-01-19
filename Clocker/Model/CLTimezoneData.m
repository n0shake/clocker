//
//  CLTimezoneData.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import "CLTimezoneData.h"
#import "CommonStrings.h"
#import "DateTools.h"
#import "CLAPI.h"
#import "PanelController.h"
#import <Parse/Parse.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>

@implementation CLTimezoneData

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self == [super init])
    {
        self.customLabel = dictionary[CLCustomLabel];
        self.timezoneID = dictionary[CLTimezoneID];
        self.latitude = dictionary[@"latitude"];
        self.longitude = dictionary[@"longitude"];
        self.place_id = dictionary[CLPlaceIdentifier];
        self.formattedAddress = dictionary[CLTimezoneName];
        self.isFavourite = [NSNumber numberWithInt:NSOffState];
    }
    
    return self;
}

- (BOOL)saveObjectToPreferences:(CLTimezoneData *)object
{
    
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:encodedObject];
    
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:CLDefaultPreferenceKey];
    
    return YES;
}

+ (instancetype)getCustomObject:(NSData *)encodedData
{
    if ([encodedData isKindOfClass:[NSDictionary class]])
    {
        CLTimezoneData *newObject = [[self alloc] initWithDictionary:(NSDictionary *)encodedData];
        return newObject;
    }
    CLTimezoneData *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
    return object;
    
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.place_id forKey:@"place_id"];
    [coder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [coder encodeObject:self.customLabel forKey:@"customLabel"];
    [coder encodeObject:self.timezoneID forKey:@"timezoneID"];
    [coder encodeObject:self.nextUpdate forKey:@"nextUpdate"];
    [coder encodeObject:self.isFavourite forKey:@"isFavourite"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self == [super init])
    {
        self.place_id = [coder decodeObjectForKey:@"place_id"];
        self.formattedAddress = [coder decodeObjectForKey:@"formattedAddress"];
        self.customLabel = [coder decodeObjectForKey:@"customLabel"];
        self.timezoneID = [coder decodeObjectForKey:@"timezoneID"];
        self.nextUpdate = [coder decodeObjectForKey:@"nextUpdate"];
        self.isFavourite = [coder decodeObjectForKey:@"isFavourite"];
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TimezoneID: %@\nFormatted Address: %@\nCustom Label: %@\nLatitude: %@\nLongitude:%@\nPlaceID: %@\nisFavourite: %@", self.timezoneID,
            self.formattedAddress,
            self.customLabel,
            self.latitude,
            self.longitude,
            self.place_id,
            self.isFavourite];
}

- (NSString *)formatStringShouldContainCity:(BOOL)value
{
    if (self.customLabel.length > 0)
    {
        return self.customLabel;
    }
    
    if ([self.formattedAddress length] > 0)
    {
        return self.formattedAddress;
    }
    else if (self.timezoneID)
    {
        NSString *timezoneID = self.timezoneID;
        
        NSRange range = [timezoneID rangeOfString:@"/"];
        if (range.location != NSNotFound)
        {
            timezoneID = [timezoneID substringWithRange:NSMakeRange(range.location+1, timezoneID.length-1 - range.location)];
        }
        return timezoneID;
    }
    else
    {
        return @"Error";
    }
    
}

/*
- (NSString *)getFormattedSunriseOrSunsetTimeAndSunImage:(CLTimezoneCellView *)cell
{
    if (!self.shouldFetchSunTimings) {
        return CLEmptyString;
    }
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSDate *sunTime = [formatter dateFromString:self.sunriseTime];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.timezoneID];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *newDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDateFormatter *dateConversion = [[NSDateFormatter alloc] init];
    dateConversion.timeZone = [NSTimeZone timeZoneWithName:self.timezoneID];
    dateConversion.dateStyle = kCFDateFormatterShortStyle;
    dateConversion.timeStyle = kCFDateFormatterShortStyle;
    dateConversion.dateFormat = @"yyyy-MM-dd HH:mm";
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if ([sunTime laterDate:[dateConversion dateFromString:newDate]] == sunTime)
    {
        cell.sunImage.image = theme.length > 0 && [theme isEqualToString:@"Default"] ?
        [NSImage imageNamed:@"Sunrise"] : [NSImage imageNamed:@"White Sunrise"];
        return [self.sunriseTime substringFromIndex:11];
    }
    else
    {
        cell.sunImage.image = theme.length > 0 && [theme isEqualToString:@"Default"] ?
        [NSImage imageNamed:@"Sunset"] : [NSImage imageNamed:@"White Sunset"];
        return [self.sunsetTime substringFromIndex:11];
    }
}*/

- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitHour
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    
    is24HourFormatSelected.boolValue ? [dateFormatter setDateFormat:@"HH:mm"] : [dateFormatter setDateFormat:@"hh:mm a"];
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.timezoneID];
    //In the format 22:10
    
    return [dateFormatter stringFromDate:newDate];
}

- (NSString *)getLocalCurrentDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    return [NSDateFormatter localizedStringFromDate:[NSDate date]
                                          dateStyle:NSDateFormatterShortStyle
                                          timeStyle:NSDateFormatterNoStyle];
    
}

- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy"
                                                           options:0
                                                            locale:[NSLocale currentLocale]];
    
    NSDate *localDate = [formatter dateFromString:systemDate];
    NSDate *timezoneDate = [formatter dateFromString:date];
    
    if (localDate == nil || timezoneDate == nil) {
        return @"Today";
    }
    
    // Specify which units we would like to use
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:localDate];
    
    if ([self.nextUpdate isKindOfClass:[NSString class]])
    {
        
        NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:units fromDate:timezoneDate];
        comps.day = comps.day + 1;
        NSDate *tomorrowMidnight = [[NSCalendar currentCalendar] dateFromComponents:comps];
        
        CLTimezoneData *newDataObject = [[CLTimezoneData alloc] init];
        newDataObject.timezoneID = self.timezoneID;
        newDataObject.formattedAddress = self.formattedAddress;
        newDataObject.latitude = self.latitude;
        newDataObject.longitude = self.longitude;
        newDataObject.customLabel = self.customLabel;
        newDataObject.place_id = self.place_id;
        newDataObject.nextUpdate = tomorrowMidnight;
        newDataObject.isFavourite = [NSNumber numberWithInt:NSOffState];
        
        PanelController *panelController;
        
        for (NSWindow *window in [[NSApplication sharedApplication] windows])
        {
            if ([window.windowController isMemberOfClass:[PanelController class]])
            {
                panelController = window.windowController;
            }
        }

        
        
        [panelController.defaultPreferences replaceObjectAtIndex:[panelController.defaultPreferences indexOfObject:self] withObject:newDataObject];
        [[NSUserDefaults standardUserDefaults] setObject:panelController.defaultPreferences forKey:CLDefaultPreferenceKey];
    }
    else if ([self.nextUpdate isKindOfClass:[NSDate class]] &&
             [self.nextUpdate isEarlierThanOrEqualTo:timezoneDate])
    {
        [self getTimeZoneForLatitude:self.latitude
                        andLongitude:self.longitude
                       andDataObject:self];
    }
    
    NSInteger daysApart = [timezoneDate daysFrom:localDate];
    
    if (daysApart == 0) {
        return @"Today";
    }
    else if (daysApart == -1)
    {
        return @"Yesterday";
    }
    else if (daysApart == 1)
    {
        return @"Tomorrow";
    }
    else
    {
        return [self getWeekdayFromInteger:weekday+2];
    }
}

- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitHour
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.timezoneID];
    
    NSNumber *relativeDayPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    if (relativeDayPreference.integerValue == 0) {
        return [self compareSystemDate:[self getLocalCurrentDate]
                        toTimezoneDate:[dateFormatter stringFromDate:newDate]];
    }
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy" options:0 locale:[NSLocale currentLocale]];
        
        NSDate *convertedDate = [formatter dateFromString:[dateFormatter stringFromDate:newDate]];
        
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:convertedDate];
        return [self getWeekdayFromInteger:weekday];
    }
}

- (void)getTimeZoneForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude andDataObject:(CLTimezoneData *)dataObject
{

    if (![CLAPI isUserConnectedToInternet])
    {
        //Could not fetch data
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://api.geonames.org/timezoneJSON?lat=%@&lng=%@&username=abhishaker17", latitude, longitude];
    
    
    [CLAPI dataTaskWithServicePath:urlString
                          bySender:self
               withCompletionBlock:^(NSError *error, NSDictionary *json) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       
                       if (json.count == 0) {
                           //No results found
                           return;
                       }
                       
                       if ([json[@"status"][@"message"]
                            isEqualToString:@"the hourly limit of 2000 credits for abhishaker17 has been exceeded. Please throttle your requests or use the commercial service."])
                       {
                           return;
                       }
                       
                       CLTimezoneData *newDataObject = [dataObject mutableCopy];
                       
                       /*
                       if (json[@"sunrise"] && json[@"sunset"]) {
                           newDataObject.sunriseTime = json[@"sunrise"];
                           newDataObject.sunsetTime = json[@"sunset"];
                       }*/
                       
                       NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
                       NSDateComponents *comps = [[NSCalendar currentCalendar] components:units fromDate:newDataObject.nextUpdate];
                       comps.day = comps.day + 1;
                       NSDate *tomorrowMidnight = [[NSCalendar currentCalendar] dateFromComponents:comps];
                       
                       dataObject.nextUpdate = tomorrowMidnight;
                       
                       
                       NSArray *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
                       
                       if (defaultPreference == nil)
                       {
                           defaultPreference = [[NSMutableArray alloc] init];
                       }
                       
                       
                       PanelController *panelController;
                       
                       for (NSWindow *window in [[NSApplication sharedApplication] windows])
                       {
                           if ([window.windowController isMemberOfClass:[PanelController class]])
                           {
                               panelController = window.windowController;
                           }
                       }
                       
                       
                       NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:defaultPreference];
                       
                       for (NSMutableDictionary *timeDictionary in panelController.defaultPreferences) {
                           if ([dataObject.place_id isEqualToString:timeDictionary[CLPlaceIdentifier]]) {
                               [newArray replaceObjectAtIndex:[panelController.defaultPreferences indexOfObject:dataObject] withObject:newDataObject];
                           }
                       }
                       
                       [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:CLDefaultPreferenceKey];
                       
                       [panelController.mainTableview reloadData];
                       
                   });

    
               }];
    
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

- (NSString *)getMenuTitle
{
    NSMutableString *menuTitle = [NSMutableString new];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *shouldCityBeShown = [userDefaults objectForKey:CLShowCityInMenu];
    NSNumber *shouldDayBeShown = [userDefaults objectForKey:CLShowDayInMenu];
    NSNumber *shouldDateBeShown = [userDefaults objectForKey:CLShowDateInMenu];
    
    if (shouldCityBeShown.boolValue == 0)
    {
        [menuTitle appendString:self.formattedAddress];
    }
    
    if (shouldDayBeShown.boolValue == 0)
    {
        NSString *substring = [self getDateForTimeZoneWithFutureSliderValue:0];
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
        NSString *date = [[NSDate date] formattedDateWithFormat:@"MMM dd" timeZone:[NSTimeZone timeZoneWithName:self.timezoneID] locale:[NSLocale currentLocale]];
        
        if (menuTitle.length > 0)
        {
            [menuTitle appendFormat:@" %@",date];
        }
        else
        {
            [menuTitle appendString:date];
        }
    }
    
    if (menuTitle.length > 0)
    {
        [menuTitle appendFormat:@" %@",[self getTimeForTimeZoneWithFutureSliderValue:0]];
    }
    else
    {
        [menuTitle appendString:[self getTimeForTimeZoneWithFutureSliderValue:0]];
    }
    
    return menuTitle;

}

- (void)sendAnalyticsData
{
    PFObject *feedbackObject = [PFObject objectWithClassName:@"CLTimezoneData"];
    feedbackObject[@"formattedAddress"] = self.formattedAddress;
    feedbackObject[@"timezoneID"] = self.timezoneID;
    feedbackObject[@"uniqueID"] = [self getSerialNumber];
    [feedbackObject saveEventually];
    
}

- (NSString *)getSerialNumber
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}
@end
