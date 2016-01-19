//
//  CLTimezoneData.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
//
//

#import <Foundation/Foundation.h>
#import "CLTimezoneCellView.h"

@interface CLTimezoneData : NSObject<NSCoding>

@property (strong, nonatomic) NSString *customLabel;
@property (strong, nonatomic) NSString *formattedAddress;
@property (strong, nonatomic) NSString *place_id;
@property (strong, nonatomic) NSString *timezoneID;
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSDate *nextUpdate;
@property (strong, nonatomic) NSNumber *isFavourite;

+ (instancetype)getCustomObject:(NSData *)encodedData;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)saveObjectToPreferences:(CLTimezoneData *)object;
- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue;
- (NSString *)getLocalCurrentDate;
- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date;
- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue;
- (void)getTimeZoneForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude andDataObject:(CLTimezoneData *)dataObject;
- (NSString *)formatStringShouldContainCity:(BOOL)value;
- (NSString *)getMenuTitle;

/*
 - (NSString *)getFormattedSunriseOrSunsetTimeAndSunImage:(CLTimezoneCellView *)cell;
 */

@end
