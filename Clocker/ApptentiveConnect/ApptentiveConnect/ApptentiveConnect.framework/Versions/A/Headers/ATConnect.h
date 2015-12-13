//
//  ATConnect.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#define kATConnectVersionString @"0.4.12"

#if TARGET_OS_IPHONE
#define kATConnectPlatformString @"iOS"
@class ATFeedbackController;
#elif TARGET_OS_MAC
#define kATConnectPlatformString @"Mac OS X"
@class ATFeedbackWindowController;
#endif

typedef enum {
	ATFeedbackControllerDefault,
	ATFeedbackControllerSimple
} ATFeedbackControllerType;


@interface ATConnect : NSObject {
@private
#if TARGET_OS_IPHONE
	ATFeedbackController *feedbackController;
	ATFeedbackController *currentFeedbackController;
#elif TARGET_OS_MAC
	ATFeedbackWindowController *feedbackWindowController;
#endif
	NSMutableDictionary *additionalFeedbackData;
	NSString *apiKey;
	BOOL showTagline;
	BOOL shouldTakeScreenshot;
	BOOL showEmailField;
	NSString *initialName;
	NSString *initialEmailAddress;
	ATFeedbackControllerType feedbackControllerType;
	NSString *customPlaceholderText;
}
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, assign) BOOL showTagline;
@property (nonatomic, assign) BOOL shouldTakeScreenshot;
@property (nonatomic, assign) BOOL showEmailField;
@property (nonatomic, copy) NSString *initialName;
@property (nonatomic, copy) NSString *initialEmailAddress;
@property (nonatomic, assign) ATFeedbackControllerType feedbackControllerType;
/*! Set this if you want some custom text to appear as a placeholder in the
 feedback text box. */
@property (nonatomic, copy) NSString *customPlaceholderText;

+ (ATConnect *)sharedConnection;

#if TARGET_OS_IPHONE
/*! 
 * Presents a feedback controller in the window of the given view controller.
 */
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController;

/*!
 * Dismisses the feedback controller. You normally won't need to call this.
 */
- (void)dismissFeedbackControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
#elif TARGET_OS_MAC
/*!
 * Presents a feedback window.
 */
- (IBAction)showFeedbackWindow:(id)sender;
#endif

/*! Adds an additional data field to any feedback sent. */
- (void)addAdditionalInfoToFeedback:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/*! Removes an additional data field from the feedback sent. */
- (void)removeAdditionalInfoFromFeedbackWithKey:(NSString *)key;

/*!
 * Returns the NSBundle corresponding to the bundle containing ATConnect's
 * images, xibs, strings files, etc.
 */
+ (NSBundle *)resourceBundle;
@end

/*! Replacement for NSLocalizedString within ApptentiveConnect. Pulls 
    localized strings out of the resource bundle. */
extern NSString *ATLocalizedString(NSString *key, NSString *comment);
