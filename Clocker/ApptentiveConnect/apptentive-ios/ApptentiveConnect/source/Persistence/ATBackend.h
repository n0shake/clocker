//
//  ATBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

NSString *const ATBackendNewAPIKeyNotification;

#define USE_STAGING 0

@class ATAppConfigurationUpdater;
@class ATFeedback;
@class ATAPIRequest;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject {
@private
	NSString *apiKey;
	ATFeedback *currentFeedback;
	BOOL networkAvailable;
	BOOL apiKeySet;
	BOOL shouldStopWorking;
	BOOL working;
}
@property (nonatomic, copy) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (nonatomic, retain) ATFeedback *currentFeedback;

+ (ATBackend *)sharedBackend;
#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! Use this to add the feedback to a queue of feedback tasks which
    will be sent in the background. */
- (void)sendFeedback:(ATFeedback *)feedback;

- (NSString *)supportDirectoryPath;

/*! Path to directory for storing attachments. */
- (NSString *)attachmentDirectoryPath;
- (NSString *)deviceUUID;

- (NSURL *)apptentiveHomepageURL;
- (NSURL *)apptentivePrivacyPolicyURL;

- (NSString *)distributionName;
@end
