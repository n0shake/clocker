//
//  CLTimezoneData.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import <Foundation/Foundation.h>

@interface CLTimezoneData : NSObject<NSCoding>

@property (strong, nonatomic) NSString *customLabel;
@property (strong, nonatomic) NSString *formattedAddress;
@property (strong, nonatomic) NSString *place_id;
@property (strong, nonatomic) NSString *sunriseTime;
@property (strong, nonatomic) NSString *sunsetTime;
@property (strong, nonatomic) NSString *timezoneID;
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSDate *nextUpdate;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)saveObjectToPreferences:(CLTimezoneData *)object;

@end
