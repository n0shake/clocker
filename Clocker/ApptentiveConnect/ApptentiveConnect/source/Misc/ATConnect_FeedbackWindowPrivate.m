//
//  ATConnect_FeedbackWindowPrivate.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/28/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATConnect_FeedbackWindowPrivate.h"


@implementation ATConnect (FeedbackWindowPrivate)
- (void)feedbackWindowDidClose:(id)sender {
    if (feedbackWindowController && feedbackWindowController == sender) {
        [feedbackWindowController autorelease];
        feedbackWindowController = nil;
    }
}
@end
