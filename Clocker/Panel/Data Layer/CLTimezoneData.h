// Copyright © 2015 Abhishek Banthia

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CLDateDisplayType) {
    CLPanelDisplay,
    CLMenuDisplay
};

typedef NS_ENUM(NSUInteger, CLSelection) {
    CLCitySelection,
    CLTimezoneSelection
};

typedef NS_ENUM(NSUInteger, CLTimezoneOverride) {
    CL12HourFormat,
    CL24HourFormat,
    CLGlobalFormat
};



@interface CLTimezoneData : NSObject<NSCoding>

@property (copy, nonatomic, readonly) NSString *customLabel;
@property (copy, nonatomic, readonly) NSString *formattedAddress;
@property (copy, nonatomic, readonly) NSString *place_id;
@property (copy, nonatomic, readonly) NSString *timezoneID;
@property (copy, nonatomic, readonly) NSNumber *latitude;
@property (copy, nonatomic, readonly) NSNumber *longitude;
@property (copy, nonatomic, readonly) NSString *note;
@property (strong, nonatomic, readonly) NSDate *nextUpdate;
@property (strong, nonatomic, readonly) NSNumber *isFavourite;
@property (strong, nonatomic, readonly) NSDate *sunriseTime;
@property (strong, nonatomic, readonly) NSDate *sunsetTime;
@property (assign, nonatomic, readonly) BOOL sunriseOrSunset; //YES for Sunrise, NO for Sunset
@property (assign, nonatomic,readonly) CLSelection selectionType;
@property (assign, nonatomic, readonly) BOOL isSystemTimezone; //Used for figuring out if we want to show a home indicator
@property (assign, nonatomic, readonly) CLTimezoneOverride overrideFormat;

+ (instancetype)getCustomObject:(NSData *)encodedData;
- (instancetype)initWithTimezoneInfo:(NSDictionary *)dictionary;

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
- (void)setLocationIndicator:(BOOL)isCurrentLocation;
- (void)setShouldOverrideGlobalTimeFormat:(NSNumber *)shouldOverride;
- (void)setNoteForTimezone:(NSString *)note;

- (NSString *)timezoneFormat;
- (NSString *)getFormattedTimezoneLabel;
- (NSString *)getTimezone;

- (BOOL)isEmpty;

@end
