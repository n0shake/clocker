//
//  ATTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATTask.h"

#define kATTaskCodingVersion 2

@implementation ATTask
@synthesize inProgress;
@synthesize finished;
@synthesize failed;
@synthesize failureCount;
@synthesize lastErrorTitle, lastErrorMessage;
@synthesize failureOkay;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		self.failureCount = 0;
		if (version >= 2) {
			self.failureCount = [(NSNumber *)[coder decodeObjectForKey:@"failureCount"] unsignedIntegerValue];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	[lastErrorTitle release], lastErrorTitle = nil;
	[lastErrorMessage release], lastErrorMessage = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATTaskCodingVersion forKey:@"version"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:self.failureCount] forKey:@"failureCount"];
}

- (BOOL)canStart {
	return YES;
}

- (BOOL)shouldArchive {
	return YES;
}

- (void)start {
	
}

- (void)stop {
	
}

- (float)percentComplete {
	return 0.0f;
}

- (NSString *)taskName {
	return @"task";
}

- (void)cleanup {
	// Do nothing by default.
}

- (NSString *)taskDescription {
	NSMutableArray *parts = [[NSMutableArray alloc] init];
	if (lastErrorTitle) {
		[parts addObject:[NSString stringWithFormat:@"lastErrorTitle: %@", lastErrorTitle]];
	}
	if (lastErrorMessage) {
		[parts addObject:[NSString stringWithFormat:@"lastErrorMessage: %@", lastErrorMessage]];
	}
	[parts addObject:[NSString stringWithFormat:@"inProgress: %@", inProgress ? @"YES" : @"NO"]];
	[parts addObject:[NSString stringWithFormat:@"finished: %@", finished ? @"YES" : @"NO"]];
	[parts addObject:[NSString stringWithFormat:@"failed: %@", failed ? @"YES" : @"NO"]];
#if	TARGET_OS_IPHONE
	[parts addObject:[NSString stringWithFormat:@"failureCount: %d", failureCount]];
#elif TARGET_OS_MAC
	[parts addObject:[NSString stringWithFormat:@"failureCount: %ld", (unsigned long)failureCount]];
#endif
	[parts addObject:[NSString stringWithFormat:@"percentComplete: %f", [self percentComplete]]];
	[parts addObject:[NSString stringWithFormat:@"taskName: %@", [self taskName]]];
	
	NSString *d = [parts componentsJoinedByString:@", "];
	[parts dealloc], parts = nil;
	return [NSString stringWithFormat:@"<%@ %p: %@>", NSStringFromClass([self class]), self, d];
}
@end
