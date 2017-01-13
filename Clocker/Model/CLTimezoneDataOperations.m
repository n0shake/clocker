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
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    
    NSNumber *showSeconds = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowSecondsInMenubar];
    
    if([showSeconds isEqualToNumber:@(0)])
    {
        dateFormatter.dateFormat = is24HourFormatSelected.boolValue ?  @"HH:mm:ss" : @"hh:mm:ss a";
    }
    else
    {
        dateFormatter.dateFormat = is24HourFormatSelected.boolValue ?  @"HH:mm" : @"hh:mm a";
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
        
        self.dataObject.customLabel.length > 0 ?
        [menuTitle appendString:self.dataObject.customLabel] :
        [menuTitle appendString:self.dataObject.formattedAddress];
        
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
        NSString *date = [[NSDate date] formattedDateWithFormat:@"MMM dd" timeZone:[NSTimeZone timeZoneWithName:self.dataObject.timezoneID] locale:[NSLocale currentLocale]];
        
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

- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy"
                                                           options:0
                                                            locale:[NSLocale currentLocale]];
    
    NSDate *localDate = [formatter dateFromString:systemDate];
    NSDate *timezoneDate = [formatter dateFromString:date];
    
    // Specify which units we would like to use
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:localDate];
    
    if ([self.dataObject.nextUpdate isKindOfClass:[NSString class]])
    {
        
        NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:units fromDate:timezoneDate];
        comps.day = comps.day + 1;
        NSDate *tomorrowMidnight = [[NSCalendar currentCalendar] dateFromComponents:comps];
        
        NSDictionary *dictionary = @{CLTimezoneID : self.dataObject.timezoneID, @"latitude" : self.dataObject.latitude,
                                     @"longitude" : self.dataObject.longitude, CLCustomLabel : self.dataObject.customLabel,
                                     CLPlaceIdentifier : self.dataObject.place_id, CLTimezoneName : self.dataObject.formattedAddress};

        
        CLTimezoneData *newDataObject = [[CLTimezoneData alloc] initWithDictionary:dictionary];
        [newDataObject setNextUpdateForSunriseSet:tomorrowMidnight];

        PanelController *panelController = [PanelController getPanelControllerInstance];
        
        (panelController.defaultPreferences)[[panelController.defaultPreferences indexOfObject:self]] = newDataObject;
        
        [[NSUserDefaults standardUserDefaults] setObject:panelController.defaultPreferences forKey:CLDefaultPreferenceKey];
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
                                       andDisplayType:(CLDateDisplayType)type
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterLongStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:self.dataObject.timezoneID];
    
    NSNumber *relativeDayPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    if (relativeDayPreference.integerValue == 0 && type == CLPanelDisplay) {
        return [self compareSystemDate:[self getLocalCurrentDate]
                        toTimezoneDate:[dateFormatter stringFromDate:newDate]];
    }
    else
    {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy" options:0 locale:[NSLocale currentLocale]];
        
        NSDate *convertedDate = [formatter dateFromString:[dateFormatter stringFromDate:newDate]];
        
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:convertedDate];
        return [self getWeekdayFromInteger:weekday];
    }
}

- (NSString *)getLocalCurrentDate
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = kCFDateFormatterLongStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
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
    
    EDSunriseSet *sunriseSetObject = [EDSunriseSet sunrisesetWithDate:[[NSCalendar autoupdatingCurrentCalendar]
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
