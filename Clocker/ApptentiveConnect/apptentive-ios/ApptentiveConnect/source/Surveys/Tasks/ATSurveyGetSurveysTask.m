//
//  ATSurveyGetSurveysTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyGetSurveysTask.h"
#import "ATBackend.h"
#import "ATSurveyParser.h"
#import "ATSurveysBackend.h"
#import "ATWebClient.h"
#import "ATWebClient+SurveyAdditions.h"
#import "PJSONKit.h"

@interface ATSurveyGetSurveysTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATSurveyGetSurveysTask
- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

- (void)dealloc {
	[self teardown];
	[super dealloc];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	self.failureOkay = YES;
	if (checkSurveysRequest == nil) {
		ATWebClient *client = [ATWebClient sharedClient];
		checkSurveysRequest = [[client requestForGettingSurveys] retain];
		checkSurveysRequest.delegate = self;
		self.inProgress = YES;
		[checkSurveysRequest start];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (checkSurveysRequest) {
		checkSurveysRequest.delegate = nil;
		[checkSurveysRequest cancel];
		[checkSurveysRequest release], checkSurveysRequest = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (checkSurveysRequest) {
		return [checkSurveysRequest percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"survey check";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		if (request == checkSurveysRequest) {
			ATSurveyParser *parser = [[ATSurveyParser alloc] init];
			
			NSArray *surveys = [parser parseMultipleSurveys:(NSData *)result];
			if (surveys == nil) {
				ATLogError(@"An error occurred parsing surveys: %@", [parser parserError]);
			} else {
				[[ATSurveysBackend sharedBackend] didReceiveNewSurveys:surveys maxAge:[request expiresMaxAge]];
			}
			checkSurveysRequest.delegate = nil;
			[checkSurveysRequest release], checkSurveysRequest = nil;
			[parser release], parser = nil;
			self.finished = YES;
		}
		[self release];
	}
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)request {
	@synchronized(self) {
		[self retain];
		if (request == checkSurveysRequest) {
			ATLogError(@"Survey request failed: %@: %@", request.errorTitle, request.errorMessage);
			self.lastErrorTitle = request.errorTitle;
			self.lastErrorMessage = request.errorMessage;
			self.failed = YES;
			[self stop];
		}
		[self release];
	}
}
@end

@implementation ATSurveyGetSurveysTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end
