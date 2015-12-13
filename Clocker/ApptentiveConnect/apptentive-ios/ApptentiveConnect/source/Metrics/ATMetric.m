//
//  ATMetric.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATMetric.h"
#import "ATConnect.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATWebClient+Metrics.h"

#define kATMetricStorageVersion 1

@implementation ATMetric
@synthesize name, info;

- (id)init {
	if ((self = [super init])) {
		info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMetricStorageVersion) {
			self.name = [coder decodeObjectForKey:@"name"];
			NSDictionary *d = [coder decodeObjectForKey:@"info"];
			if (info) {
				[info release], info = nil;
			}
			if (d != nil) {
				info = [d mutableCopy];
			} else {
				info = [[NSMutableDictionary alloc] init];
			}
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInt:kATMetricStorageVersion forKey:@"version"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.info forKey:@"info"];
}

- (void)dealloc {
	[name release], name = nil;
	[info release], info = nil;
	[super dealloc];
}

- (void)setValue:(id)value forKey:(NSString *)key {
	[info setValue:value forKey:key];
}

- (void)addEntriesFromDictionary:(NSDictionary *)dictionary {
	if (dictionary != nil) {
		[info addEntriesFromDictionary:dictionary];
	}
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];
	
	if (self.name) [d setObject:self.name forKey:@"record[metric][event]"];
	
	if (self.info) {
		for (NSString *key in info) {
			NSString *recordKey = [NSString stringWithFormat:@"record[metric][data][%@]", key];
			NSObject *value = [info objectForKey:key];
			if ([value isKindOfClass:[NSDate class]]) {
				value = [ATUtilities stringRepresentationOfDate:(NSDate *)value];
			}
			[d setObject:value forKey:recordKey];
		}
	}
	return d;
}

- (ATAPIRequest *)requestForSendingRecord {
	return [[ATWebClient sharedClient] requestForSendingMetric:self];
}
@end
