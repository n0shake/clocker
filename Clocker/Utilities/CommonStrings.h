//
//  CommonStrings.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/11/15.
//
//

#import <Foundation/Foundation.h>

#define NSLocalizedFormatString(fmt, ...) [NSString stringWithFormat:NSLocalizedString(fmt, nil), __VA_ARGS__]

@interface CommonStrings : NSObject

extern NSString *const CLEmptyString;
extern NSString *const CLDefaultPreferenceKey;
extern NSString *const CLTimezoneName;
extern NSString *const CLCustomLabel;
extern NSString *const CL24hourFormatSelectedKey;
extern NSString *const CLDragSessionKey;
extern NSString *const CLCustomLabelChangedNotification;
extern NSString *const CLTimezoneID;
extern NSString *const CLPlaceIdentifier;
extern NSString *const CLRelativeDateKey;
extern NSString *const CLThemeKey;
extern NSString *const CLShowDayInMenu;
extern NSString *const CLShowDateInMenu;
extern NSString *const CLShowPlaceInMenu;
extern NSString *const CLDisplayFutureSliderKey;
extern NSString *const CLStartAtLogin;
extern NSString *const CLShowAppInForeground;
extern NSString *const CLSunriseSunsetTime;
extern NSString *const CLLocationSearchURL;

@end
