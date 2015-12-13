//
//  FeedbackDemoAppDelegate.m
//  FeedbackDemo
//
//  Created by Andrew Wooster on 5/30/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "FeedbackDemoAppDelegate.h"
#import <ApptentiveConnect/ATConnect.h>
#import <ApptentiveConnect/ATAppRatingFlow.h>
#import "defines.h"

@implementation FeedbackDemoAppDelegate

@synthesize window;
@synthesize versionTextField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    [[ATConnect sharedConnection] setApiKey:kApptentiveAPIKey];
	self.versionTextField.stringValue = [NSString stringWithFormat:@"ApptentiveConnect v%@", kATConnectVersionString];
    ATAppRatingFlow *ratingFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
    [ratingFlow appDidLaunch:YES];
}

- (IBAction)showFeedbackWindow:(id)sender {
    [[ATConnect sharedConnection] showFeedbackWindow:sender];
}

- (IBAction)showFeedbackWindowForFeedback:(id)sender {
    [[ATConnect sharedConnection] showFeedbackWindow:self];
}

- (IBAction)showRatingFlow:(id)sender {
    ATAppRatingFlow *ratingFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
    [ratingFlow showEnjoymentDialog:sender];
}
@end
