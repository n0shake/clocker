//
//  CLTimezoneData.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import "CLTimezoneData.h"
#import "CommonStrings.h"

@implementation CLTimezoneData

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self == [super init])
    {
        self.customLabel = dictionary[CLCustomLabel];
        self.sunriseTime = CLEmptyString;
        self.sunsetTime = CLEmptyString;
        self.timezoneID = dictionary[CLTimezoneName];
        self.latitude = dictionary[@"latitude"];
        self.longitude = dictionary[@"longitude"];
        self.place_id = dictionary[CLPlaceIdentifier];
        self.formattedAddress = dictionary[CLTimezoneName];
    }
    
    return self;
}

- (BOOL)saveObjectToPreferences:(CLTimezoneData *)object
{
    
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:encodedObject];
    
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"checking"];
    
    [self getCustomObject];
    
    return YES;
}

- (void)getCustomObject
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *encodedObject = [defaults objectForKey:@"checking"];
    CLTimezoneData *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject[0]];
    NSLog(@"Object:%@", object.place_id);
    
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.place_id forKey:@"place_id"];
    [coder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [coder encodeObject:self.customLabel forKey:@"customLabel"];
    [coder encodeObject:self.sunriseTime forKey:@"sunriseTime"];
    [coder encodeObject:self.sunsetTime forKey:@"sunsetTime"];
    [coder encodeObject:self.timezoneID forKey:@"timezoneID"];
    
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self == [super init])
    {
        self.place_id = [coder decodeObjectForKey:@"place_id"];
        self.formattedAddress = [coder decodeObjectForKey:@"formattedAddress"];
        self.customLabel = [coder decodeObjectForKey:@"customLabel"];
        self.sunsetTime = [coder decodeObjectForKey:@"sunsetTime"];
        self.sunriseTime = [coder decodeObjectForKey:@"sunriseTime"];
        self.timezoneID = [coder decodeObjectForKey:@"timezoneID"];
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TimezoneID:%@\nFormatted Address:%@\nCustom Label:%@\nLatitude:%@\nLongitude:%@\nSunrise:%@\nSunset:%@\nPlaceID:%@", self.timezoneID,
            self.formattedAddress,
            self.customLabel,
            self.latitude,
            self.longitude,
            self.sunriseTime,
            self.sunsetTime,
            self.place_id];
}

@end
