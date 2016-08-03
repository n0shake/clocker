//
//  CLTimezoneDataOperations.h
//  Clocker
//
//  Created by Abhishek Banthia on 7/24/16.
//
//

#import <Foundation/Foundation.h>
#import "CLTimezoneData.h"

@interface CLTimezoneDataOperations : NSObject

@property (readonly) CLTimezoneData *dataObject;

- (instancetype)initWithTimezoneData:(CLTimezoneData *)timezoneData;
- (NSString *)getTimeForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue;
- (void)save;
- (NSString *)getMenuTitle;
- (NSString *)getFormattedSunriseOrSunsetTimeAndSliderValue:(NSInteger)sliderValue;
- (NSString *)getDateForTimeZoneWithFutureSliderValue:(NSInteger)futureSliderValue
                                       andDisplayType:(CLDateDisplayType)type;

@end
