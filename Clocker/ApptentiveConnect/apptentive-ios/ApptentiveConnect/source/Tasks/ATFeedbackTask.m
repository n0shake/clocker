//
//  ATFeedbackTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedbackTask.h"
#import "ATLog.h"
#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATWebClient.h"

#define kATFeedbackTaskCodingVersion 1

@interface ATFeedbackTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATFeedbackTask
@synthesize feedback;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATFeedbackTaskCodingVersion) {
			self.feedback = [coder decodeObjectForKey:@"feedback"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATFeedbackTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.feedback forKey:@"feedback"];
}

- (void)dealloc {
	[self teardown];
	[feedback release], feedback = nil;
	[super dealloc];
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		request = [[self.feedback requestForSendingRecord] retain];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"feedback";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		self.finished = YES;
		[self stop];
		[self release];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		[self retain];
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		ATLogInfo(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
		[self release];
	}
}

- (void)cleanup {
	[feedback cleanup];
}
@end

@implementation ATFeedbackTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end
