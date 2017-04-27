//
//  CLTimezoneData.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import "CLAPIConnector.h"
#import "CLTimezoneData.h"
#import "CommonStrings.h"
#import "DateTools.h"
#import "PanelController.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#import "CLTimezoneDataOperations.h"

@interface CLTimezoneData ()

@property (copy, nonatomic) NSString *customLabel;
@property (copy, nonatomic) NSString *formattedAddress;
@property (copy, nonatomic) NSString *place_id;
@property (copy, nonatomic) NSString *timezoneID;
@property (copy, nonatomic) NSString *latitude;
@property (copy, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSDate *nextUpdate;
@property (strong, nonatomic) NSNumber *isFavourite;
@property (strong, nonatomic) NSDate *sunriseTime;
@property (strong, nonatomic) NSDate *sunsetTime;
@property (assign, nonatomic) BOOL sunriseOrSunset; //YES for Sunrise, NO for Sunset
@property (assign, nonatomic) CLSelection selectionType;

@end

@implementation CLTimezoneData

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
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
    }
    
    return self;
}

+ (instancetype)getCustomObject:(NSData *)encodedData
{
    
    if (encodedData)
    {
        if ([encodedData isKindOfClass:[NSDictionary class]])
        {
            CLTimezoneData *newObject = [[self alloc] initWithDictionary:(NSDictionary *)encodedData];
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
        self.longitude = [coder decodeObjectForKey:@"longitude"];
        self.isFavourite = [coder decodeObjectForKey:@"isFavourite"];
        self.sunriseTime = [coder decodeObjectForKey:@"sunriseTime"];
        self.sunsetTime = [coder decodeObjectForKey:@"sunsetTime"];
        self.selectionType = [coder decodeIntegerForKey:@"selectionType"];
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TimezoneID: %@\nFormatted Address: %@\nCustom Label: %@\nLatitude: %@\nLongitude:%@\nPlaceID: %@\nisFavourite: %@\nSunrise Time: %@\nSunset Time: %@\nSelection Type: %zd", self.timezoneID,
            self.formattedAddress,
            self.customLabel,
            self.latitude,
            self.longitude,
            self.place_id,
            self.isFavourite,
            self.sunriseTime,
            self.sunsetTime,
            self.selectionType];
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

- (void)setSunriseOrSunsetForTimezone:(BOOL)sunriseOrSunset
{
    self.sunriseOrSunset = sunriseOrSunset;
}

- (void)setLatitudeForTimezone:(NSString *)latitude
{
    self.latitude = latitude;
}

- (void)setLongitudeForTimezone:(NSString *)longitude
{
    self.longitude = longitude;
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

@end
