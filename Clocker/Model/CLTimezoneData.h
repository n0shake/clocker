//
//  CLTimezoneData.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/22/15.
// 
//

#import <Foundation/Foundation.h>
#import "CLTimezoneCellView.h"

typedef NS_ENUM(NSUInteger, CLDateDisplayType) {
    CLPanelDisplay,
    CLMenuDisplay
};

typedef NS_ENUM(NSUInteger, CLSelection) {
    CLCitySelection,
    CLTimezoneSelection
};

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
@property (assign, nonatomic) CLSelection selectionType;

+ (instancetype)getCustomObject:(NSData *)encodedData;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue;
- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date;
- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue andDisplayType:(CLDateDisplayType)type;
- (NSString *)formatStringShouldContainCity:(BOOL)value;
@property (NS_NONATOMIC_IOSONLY, getter=getMenuTitle, readonly, copy) NSString *menuTitle;
-(NSString *)getFormattedSunriseOrSunsetTimeAndSliderValue:(NSInteger)sliderValue;
- (void)save;

@end
