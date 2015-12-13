//
//  ATFeedbackMetrics.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATFeedbackDidShowWindowNotification;
NSString *const ATFeedbackDidHideWindowNotification;

NSString *const ATFeedbackWindowTypeKey;
NSString *const ATFeedbackWindowHideEventKey;

typedef enum {
	ATFeedbackWindowTypeFeedback,
	ATFeedbackWindowTypeInfo,
} ATFeedbackWindowType;

typedef enum {
	ATFeedbackEventTappedCancel,
	ATFeedbackEventTappedSend,
} ATFeedbackEvent;
