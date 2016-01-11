//
//  CLTimezoneData.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import "CLTimezoneData.h"

@implementation CLTimezoneData

-(void)initWithDictionary:(NSDictionary *)dictionary
{
    
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

@end
