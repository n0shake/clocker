//
//  ATAppRatingMetrics.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Constants for Metrics

NSString *const ATAppRatingDidPromptForEnjoymentNotification;
NSString *const ATAppRatingDidClickEnjoymentButtonNotification;

NSString *const ATAppRatingDidPromptForRatingNotification;
NSString *const ATAppRatingDidClickRatingButtonNotification;

NSString *const ATAppRatingButtonTypeKey;

typedef enum {
	ATAppRatingEnjoymentButtonTypeUnknown,
	ATAppRatingEnjoymentButtonTypeYes,
	ATAppRatingEnjoymentButtonTypeNo,
} ATAppRatingEnjoymentButtonType;

typedef enum {
	ATAppRatingButtonTypeUnknown,
	ATAppRatingButtonTypeNo,
	ATAppRatingButtonTypeRemind,
	ATAppRatingButtonTypeRateApp,
} ATAppRatingButtonType;

