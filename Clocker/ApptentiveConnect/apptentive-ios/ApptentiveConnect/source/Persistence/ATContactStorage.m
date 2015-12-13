//
//  ATContactStorage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATContactStorage.h"
#import "ATLog.h"
#import "ATBackend.h"

#define kATContactStorageVersion 1

// Interval, in seconds, after which we'll update the contact storage from the
// server, if it hasn't been modified locally.
#define kATContactStorageUpdateInterval (60*60*24*7)

static ATContactStorage *sharedContactStorage = nil;

@interface ATContactStorage (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATContactStorage
@synthesize name, email, phone;

+ (NSString *)contactStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"contactinfo.objects"];
}

+ (BOOL)serializedVersionExists {
	NSFileManager *fm = [NSFileManager defaultManager];
	return [fm fileExistsAtPath:[ATContactStorage contactStoragePath]];
}


+ (ATContactStorage *)sharedContactStorage {
	@synchronized(self) {
		if (sharedContactStorage == nil) {
			if ([ATContactStorage serializedVersionExists]) {
				@try {
					sharedContactStorage = [[NSKeyedUnarchiver unarchiveObjectWithFile:[ATContactStorage contactStoragePath]] retain];
				}
				@catch (NSException *exception) {
					ATLogError(@"Unable to unarchive cstorage: %@", exception);
				}
			}
			if (!sharedContactStorage) {
				sharedContactStorage = [[ATContactStorage alloc] init];
			}
		}
	}
	return sharedContactStorage;
}

+ (void)releaseSharedContactStorage {
	@synchronized(self) {
		if (sharedContactStorage != nil) {
			[sharedContactStorage save];
			[sharedContactStorage release];
			sharedContactStorage = nil;
		}
	}
}

- (void)save {
	@synchronized(self) {
		[NSKeyedArchiver archiveRootObject:sharedContactStorage toFile:[ATContactStorage contactStoragePath]];
	}
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATContactStorageVersion) {
			self.name = [coder decodeObjectForKey:@"name"];
			self.email = [coder decodeObjectForKey:@"email"];
			self.phone = [coder decodeObjectForKey:@"phone"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATContactStorageVersion forKey:@"version"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.email forKey:@"email"];
	[coder encodeObject:self.phone forKey:@"phone"];
}

- (void)dealloc {
	[self teardown];
	[super dealloc];
}
@end

@implementation ATContactStorage (Private)
- (void)setup {
	
}

- (void)teardown {
	self.name = nil;
	self.phone = nil;
	self.email = nil;
}
@end
