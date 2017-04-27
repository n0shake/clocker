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

@property (copy, nonatomic, readonly) NSString *customLabel;
@property (copy, nonatomic, readonly) NSString *formattedAddress;
@property (copy, nonatomic, readonly) NSString *place_id;
@property (copy, nonatomic, readonly) NSString *timezoneID;
@property (copy, nonatomic, readonly) NSString *latitude;
@property (copy, nonatomic, readonly) NSString *longitude;
@property (strong, nonatomic, readonly) NSDate *nextUpdate;
@property (strong, nonatomic, readonly) NSNumber *isFavourite;
@property (strong, nonatomic, readonly) NSDate *sunriseTime;
@property (strong, nonatomic, readonly) NSDate *sunsetTime;
@property (assign, nonatomic, readonly) BOOL sunriseOrSunset; //YES for Sunrise, NO for Sunset
@property (assign, nonatomic,readonly) CLSelection selectionType;

+ (instancetype)getCustomObject:(NSData *)encodedData;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)setLabelForTimezone:(NSString *)customLabel;
- (void)setIDForTimezone:(NSString *)uniqueID;
- (void)setFormattedAddressForTimezone:(NSString *)address;
- (void)setFavouriteValueForTimezone:(NSNumber *)favouriteValue;
- (void)setNextUpdateForSunriseSet:(NSDate *)nextUpdate;
- (void)setSunsetTimeForTimezone:(NSDate *)sunsetTime;
- (void)setSunriseTimeForTimezone:(NSDate *)sunriseTime;
- (void)setSunriseOrSunsetForTimezone:(BOOL)sunriseOrSunset;
- (void)setLatitudeForTimezone:(NSString *)latitude;
- (void)setLongitudeForTimezone:(NSString *)longitude;
- (NSString *)getFormattedTimezoneLabel;
- (BOOL)isEmpty;

@end
