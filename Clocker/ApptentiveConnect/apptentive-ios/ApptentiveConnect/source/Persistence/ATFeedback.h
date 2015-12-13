//
//  ATFeedback.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

#import "ATRecord.h"

typedef enum {
	ATFeedbackTypeFeedback,
	ATFeedbackTypePraise,
	ATFeedbackTypeBug,
	ATFeedbackTypeQuestion
} ATFeedbackType;

typedef enum {
	ATFeedbackSourceUnknown,
	ATFeedbackSourceEnjoymentDialog,
} ATFeedbackSource;

typedef enum {
	ATFeedbackImageSourceScreenshot,
	ATFeedbackImageSourceCamera,
	ATFeedbackImageSourcePhotoLibrary,
} ATFeedbackImageSource;

@interface ATFeedback : ATRecord <NSCoding> {
@private
	NSMutableDictionary *extraData;
	ATFeedbackType type;
	NSString *text;
	NSString *name;
	NSString *email;
	NSString *phone;
	ATFeedbackSource source;
#if TARGET_OS_IPHONE
	UIImage *screenshot;
#elif TARGET_OS_MAC
	NSImage *screenshot;
#endif
	ATFeedbackImageSource imageSource;
	
	NSString *screenshotFilename;
}
@property (nonatomic, assign) ATFeedbackType type;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, assign) ATFeedbackSource source;
@property (nonatomic, assign) ATFeedbackImageSource imageSource;

- (NSDictionary *)apiDictionary;
- (void)addExtraDataFromDictionary:(NSDictionary *)dictionary;

#if TARGET_OS_IPHONE
- (void)setScreenshot:(UIImage *)screenshot;
- (UIImage *)copyScreenshot;
#elif TARGET_OS_MAC
- (void)setScreenshot:(NSImage *)screenshot;
- (NSImage *)copyScreenshot;
#endif
- (BOOL)hasScreenshot;
- (NSData *)dataForScreenshot;
@end
