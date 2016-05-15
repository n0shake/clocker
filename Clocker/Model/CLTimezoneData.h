//
//  CLTimezoneData.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
// 
//

#import <Foundation/Foundation.h>
#import "CLTimezoneCellView.h"

typedef enum : NSUInteger {
    CLPanelDisplay,
    CLMenuDisplay
} CLDateDisplayType;

@interface CLTimezoneData : NSObject<NSCoding>

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

+ (instancetype)getCustomObject:(NSData *)encodedData;
+ (void)setInitialTimezoneData;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)saveObjectToPreferences;
- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue;
- (NSString *)getLocalCurrentDate;
- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date;
- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue andDisplayType:(CLDateDisplayType)type;
- (NSString *)formatStringShouldContainCity:(BOOL)value;
- (NSString *)getMenuTitle;
-(NSString *)getFormattedSunriseOrSunsetTimeAndSliderValue:(NSInteger)sliderValue;

/*
 - (NSString *)getFormattedSunriseOrSunsetTimeAndSunImage:(CLTimezoneCellView *)cell;
 */

@end
