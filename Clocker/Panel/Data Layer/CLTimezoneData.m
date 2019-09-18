// Copyright © 2015 Abhishek Banthia

#import "CLTimezoneData.h"
#import "CommonStrings.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#import "Clocker-Swift.h"

@interface CLTimezoneData ()

@property (copy, nonatomic) NSString *customLabel;
@property (copy, nonatomic) NSString *formattedAddress;
@property (copy, nonatomic) NSString *place_id;
@property (copy, nonatomic) NSString *timezoneID;
@property (copy, nonatomic) NSNumber *latitude;
@property (copy, nonatomic) NSNumber *longitude;
@property (copy, nonatomic) NSString *note;
@property (strong, nonatomic) NSDate *nextUpdate;
@property (strong, nonatomic) NSNumber *isFavourite;
@property (strong, nonatomic) NSDate *sunriseTime;
@property (strong, nonatomic) NSDate *sunsetTime;
@property (assign, nonatomic) BOOL sunriseOrSunset; //YES for Sunrise, NO for Sunset
@property (assign, nonatomic) CLSelection selectionType;
@property (assign, nonatomic) BOOL isSystemTimezone;
@property (assign, nonatomic) CLTimezoneOverride overrideFormat;
@end

@implementation CLTimezoneData

-(instancetype)initWithTimezoneInfo:(NSDictionary *)dictionary
{
    self = [super init];
    
    if (self)
    {
        self.customLabel = dictionary[CLCustomLabel];
        self.timezoneID = dictionary[CLTimezoneID];
        self.latitude = dictionary[@"latitude"];
        self.longitude = dictionary[@"longitude"];
        self.place_id = dictionary[CLPlaceIdentifier];
        self.formattedAddress = dictionary[CLTimezoneName];
        self.isFavourite = @(NSOffState);
        self.selectionType = CLCitySelection;
        self.note = dictionary[@"note"];
        self.isSystemTimezone = NO;
        self.overrideFormat = CLGlobalFormat;
    }
    
    return self;
}

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.selectionType = CLTimezoneSelection;
        self.isFavourite = @(NSOffState);
        self.note = CLEmptyString;
        self.isSystemTimezone = NO;
        self.overrideFormat = CLGlobalFormat;
    }
    
    return self;
}

+ (instancetype)getCustomObject:(NSData *)encodedData
{
    
    if (encodedData)
    {
        if ([encodedData isKindOfClass:[NSDictionary class]])
        {
            CLTimezoneData *newObject = [[self alloc] initWithTimezoneInfo:(NSDictionary *)encodedData];
            return newObject;
        }
        
        
        CLTimezoneData *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
        return object;
        
    }
    
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.place_id forKey:@"place_id"];
    [coder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [coder encodeObject:self.customLabel forKey:@"customLabel"];
    [coder encodeObject:self.timezoneID forKey:@"timezoneID"];
    [coder encodeObject:self.nextUpdate forKey:@"nextUpdate"];
    [coder encodeObject:self.latitude forKey:@"latitude"];
    [coder encodeObject:self.longitude forKey:@"longitude"];
    [coder encodeObject:self.isFavourite forKey:@"isFavourite"];
    [coder encodeObject:self.sunriseTime forKey:@"sunriseTime"];
    [coder encodeObject:self.sunsetTime forKey:@"sunsetTime"];
    [coder encodeInteger:self.selectionType forKey:@"selectionType"];
    [coder encodeObject:self.note forKey:@"note"];
    [coder encodeBool:self.isSystemTimezone forKey:@"isSystemTimezone"];
    [coder encodeInteger:self.overrideFormat forKey:@"overrideFormat"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self)
    {
        self.place_id = [coder decodeObjectForKey:@"place_id"];
        self.formattedAddress = [coder decodeObjectForKey:@"formattedAddress"];
        self.customLabel = [coder decodeObjectForKey:@"customLabel"];
        self.timezoneID = [coder decodeObjectForKey:@"timezoneID"];
        self.nextUpdate = [coder decodeObjectForKey:@"nextUpdate"];
        self.latitude = [coder decodeObjectForKey:@"latitude"];
        self.note = [coder decodeObjectForKey:@"note"];
        self.longitude = [coder decodeObjectForKey:@"longitude"];
        self.isFavourite = [coder decodeObjectForKey:@"isFavourite"];
        self.sunriseTime = [coder decodeObjectForKey:@"sunriseTime"];
        self.sunsetTime = [coder decodeObjectForKey:@"sunsetTime"];
        self.selectionType = [coder decodeIntegerForKey:@"selectionType"];
        self.isSystemTimezone = NO;
        self.overrideFormat = [coder decodeIntegerForKey:@"overrideFormat"];
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TimezoneID: %@\nFormatted Address: %@\nCustom Label: %@\nLatitude: %@\nLongitude:%@\nPlaceID: %@\nisFavourite: %@\nSunrise Time: %@\nSunset Time: %@\nSelection Type: %zd\nNote: %@\nSystemTimezone: %hhd\nOverride: %zd", self.timezoneID,
            self.formattedAddress,
            self.customLabel,
            self.latitude,
            self.longitude,
            self.place_id,
            self.isFavourite,
            self.sunriseTime,
            self.sunsetTime,
            self.selectionType,
            self.note,
            self.isSystemTimezone,
            self.overrideFormat];
}

- (NSString *)getFormattedTimezoneLabel
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

- (void)setLabelForTimezone:(NSString *)customLabel
{
   self.customLabel = customLabel.length > 0 ? customLabel : CLEmptyString;
}

- (void)setIDForTimezone:(NSString *)uniqueID
{
    self.timezoneID = uniqueID;
}

- (void)setLocationIndicator:(BOOL)isCurrentLocation {
    self.isSystemTimezone = isCurrentLocation;
}

-(void)setFormattedAddressForTimezone:(NSString *)address
{
    self.formattedAddress = address;
}

-(void)setFavouriteValueForTimezone:(NSNumber *)favouriteValue
{
    self.isFavourite = favouriteValue;
}

-(void)setNextUpdateForSunriseSet:(NSDate *)nextUpdate
{
    self.nextUpdate = nextUpdate;
}

-(void)setSunsetTimeForTimezone:(NSDate *)sunsetTime
{
    self.sunsetTime = sunsetTime;
}

-(void)setSunriseTimeForTimezone:(NSDate *)sunriseTime
{
    self.sunriseTime = sunriseTime;
}

-(void)setShouldOverrideGlobalTimeFormat:(NSNumber *)shouldOverride
{
    if ([shouldOverride isEqualToNumber:@(0)]) {
        NSLog(@"Updated to 12 Hour Format");
        self.overrideFormat = CL12HourFormat;
    } else if ([shouldOverride isEqualToNumber:@(1)]) {
        NSLog(@"Updated to 24 Hour Format");
        self.overrideFormat = CL24HourFormat;
    } else {
        NSLog(@"Updated to Global Hour Format");
        self.overrideFormat = CLGlobalFormat;
    }
}

- (NSString *)timezoneFormat {
    
    NSString *dateFormat = nil;
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    NSNumber *showSeconds = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowSecondsInMenubar];
    
    if([showSeconds isEqualToNumber:@(0)])
    {
        if (self.overrideFormat == CLGlobalFormat) {
            dateFormat = [is24HourFormatSelected isEqualToNumber:@(0)] ? @"h:mm:ss a" : @"H:mm:ss";
        } else if (self.overrideFormat == CL12HourFormat) {
            dateFormat = @"h:mm:ss a";
            
        } else if (self.overrideFormat == CL24HourFormat) {
            dateFormat = @"H:mm:ss";
        } else {
            assert("Something's wrong here.");
        }
    }
    else
    {
        if (self.overrideFormat == CLGlobalFormat) {
            dateFormat = [is24HourFormatSelected isEqualToNumber:@(0)] ? @"h:mm a" : @"H:mm";
        } else if (self.overrideFormat == CL12HourFormat) {
            dateFormat = @"h:mm a";
        } else if (self.overrideFormat == CL24HourFormat) {
            dateFormat = @"H:mm";
        } else {
            assert("Something's wrong here.");
        }
    }
    
    return dateFormat;
}

- (void)setSunriseOrSunsetForTimezone:(BOOL)sunriseOrSunset
{
    self.sunriseOrSunset = sunriseOrSunset;
}

- (void)setLatitudeForTimezone:(NSNumber *)latitude
{
    self.latitude = latitude;
}

- (void)setLongitudeForTimezone:(NSNumber *)longitude
{
    self.longitude = longitude;
}

- (void)setNoteForTimezone:(NSString *)note
{
    self.note = note;
}

- (NSString *)getTimezone {
    
    if (self.isSystemTimezone == YES) {
        [NSTimeZone resetSystemTimeZone];
        [self setTimezoneID:[[NSTimeZone systemTimeZone] name]];
        [self setFormattedAddress:[[NSTimeZone systemTimeZone] name]];
        return [[NSTimeZone systemTimeZone] name];
    } else {
        return self.timezoneID;
    }
    
}

- (BOOL)isEmpty
{
    if ([self checkPropertyForNil:self.timezoneID] || [self checkPropertyForNil:self.place_id] ||
        [self checkPropertyForNil:self.formattedAddress] || [self checkPropertyForNil:self.latitude] || [self checkPropertyForNil:self.longitude]) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)checkPropertyForNil:(id)property
{
    if (property == nil || property == [NSNull null]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isEqual:(id)object {
    
    if (![self isKindOfClass:[self class]] || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    CLTimezoneData *comparisonObject = (CLTimezoneData *)object;
    return [self.place_id isEqualToString:comparisonObject.place_id];
}

- (NSUInteger)hash{
    return self.place_id.hash ^ self.timezoneID.hash;
}

@end
