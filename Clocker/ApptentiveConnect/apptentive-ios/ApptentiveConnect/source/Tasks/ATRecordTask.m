//
//  ATRecordTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATRecordTask.h"
#import "ATLog.h"
#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATWebClient.h"

#define kATRecordTaskCodingVersion 1

@interface ATRecordTask (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATRecordTask
@synthesize record;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATRecordTaskCodingVersion) {
			self.record = [coder decodeObjectForKey:@"record"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATRecordTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.record forKey:@"record"];
}

- (void)dealloc {
	[self teardown];
	[record release], record = nil;
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
		request = [[self.record requestForSendingRecord] retain];
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
	return @"record";
}

- (void)cleanup {
	[record cleanup];
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		[self retain];
		[self stop];
		self.finished = YES;
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
@end

@implementation ATRecordTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}
@end
