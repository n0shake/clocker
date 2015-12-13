//
//  ATFeedback.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedback.h"
#import "ATLog.h"
#import "ATConnect.h"
#import "ATBackend.h"
#import "ATUtilities.h"
#import "ATWebClient.h"

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif


#define kFeedbackCodingVersion 2

@interface ATFeedback (Private)
- (void)setup;
- (ATFeedbackType)feedbackTypeFromString:(NSString *)feedbackString;
- (NSString *)stringForFeedbackType:(ATFeedbackType)feedbackType;
- (NSString *)stringForSource:(ATFeedbackSource)aSource;
- (NSString *)fullPathForScreenshotFilename:(NSString *)filename;
- (void)createScreenshotSidecarIfNecessary;
- (void)deleteScreenshotSidecar;
@end

@implementation ATFeedback
@synthesize type, text, name, email, phone, source, imageSource;
- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (void)dealloc {
	[extraData release], extraData = nil;
	[text release], text = nil;
	[name release], name = nil;
	[email release], email = nil;
	[phone release], phone = nil;
	[screenshot release], screenshot = nil;
	[screenshotFilename release], screenshotFilename = nil;
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		[self setup];
		int version = [coder decodeIntForKey:@"version"];
		if ([coder containsValueForKey:@"source"]) {
			self.source = [coder decodeIntForKey:@"source"];
		} else {
			self.source = ATFeedbackSourceUnknown;
		}
		if (version == 1) {
			self.type = [self feedbackTypeFromString:[coder decodeObjectForKey:@"type"]];
			self.text = [coder decodeObjectForKey:@"text"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.email = [coder decodeObjectForKey:@"email"];
			self.phone = [coder decodeObjectForKey:@"phone"];
			if ([coder containsValueForKey:@"screenshot"]) {
				NSData *data = [coder decodeObjectForKey:@"screenshot"];
#if TARGET_OS_IPHONE
				screenshot = [[UIImage imageWithData:data] retain];
#elif TARGET_OS_MAC
				screenshot = [[NSImage alloc] initWithData:data];
#endif
			}
		} else if (version == kFeedbackCodingVersion) {
			self.type = [coder decodeIntForKey:@"type"];
			self.text = [coder decodeObjectForKey:@"text"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.email = [coder decodeObjectForKey:@"email"];
			self.phone = [coder decodeObjectForKey:@"phone"];
			if ([coder containsValueForKey:@"screenshot"]) {
				NSData *data = [coder decodeObjectForKey:@"screenshot"];
#if TARGET_OS_IPHONE
				screenshot = [[UIImage imageWithData:data] retain];
#elif TARGET_OS_MAC
				screenshot = [[NSImage alloc] initWithData:data];
#endif
			}
			if ([coder containsValueForKey:@"screenshotFilename"]) {
				screenshotFilename = [[coder decodeObjectForKey:@"screenshotFilename"] retain];
			}
			NSDictionary *oldExtraData = [coder decodeObjectForKey:@"extraData"];
			if (oldExtraData != nil) {
				[extraData addEntriesFromDictionary:oldExtraData];
			}
		} else {
			[self release];
			return nil;
		}
		
		// Upgrade screenshot data, if necessary.
		[self createScreenshotSidecarIfNecessary];
		if (screenshotFilename && screenshot != nil) {
			[screenshot release], screenshot = nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInt:kFeedbackCodingVersion forKey:@"version"];
	[coder encodeInt:self.type forKey:@"type"];
	[coder encodeObject:self.text forKey:@"text"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.email forKey:@"email"];
	[coder encodeObject:self.phone forKey:@"phone"];
	if (self.source != ATFeedbackSourceUnknown) {
		[coder encodeInt:self.source forKey:@"source"];
	}
	[coder encodeObject:extraData forKey:@"extraData"];
	[self createScreenshotSidecarIfNecessary];
	[coder encodeObject:screenshotFilename forKey:@"screenshotFilename"];
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];
	if (self.name) [d setObject:self.name forKey:@"record[user][name]"];
	if (self.email) [d setObject:self.email forKey:@"record[user][email]"];
	if (self.phone) [d setObject:self.phone forKey:@"record[user][phone_number]"];
	if (self.text) [d setObject:self.text forKey:@"record[feedback][feedback]"];
	[d setObject:[self stringForFeedbackType:self.type] forKey:@"record[feedback][type]"];
	NSString *sourceString = [self stringForSource:self.source];
	if (sourceString != nil) {
		[d setObject:sourceString forKey:@"record[feedback][source]"];
	}
	if (extraData && [extraData count] > 0) {
		for (NSString *key in extraData) {
			NSString *fullKey = [NSString stringWithFormat:@"record[data][%@]", key];
			[d setObject:[extraData objectForKey:key] forKey:fullKey];
		}
	}
	return d;
}

- (void)addExtraDataFromDictionary:(NSDictionary *)dictionary {
	[extraData addEntriesFromDictionary:dictionary];
}

- (ATAPIRequest *)requestForSendingRecord {
	return [[ATWebClient sharedClient] requestForPostingFeedback:self];
}

- (void)cleanup {
	[self deleteScreenshotSidecar];
	[super cleanup];
}

#if TARGET_OS_IPHONE
- (void)setScreenshot:(UIImage *)aScreenshot
#elif TARGET_OS_MAC
- (void)setScreenshot:(NSImage *)aScreenshot
#endif
{
	if (screenshot != aScreenshot) {
		[screenshot release], screenshot = nil;
		[self deleteScreenshotSidecar];
		screenshot = [aScreenshot retain];
	}
}

#if TARGET_OS_IPHONE
- (UIImage *)copyScreenshot
#elif TARGET_OS_MAC
- (NSImage *)copyScreenshot
#endif
{
	if (screenshot) {
		return [screenshot copy];
	} else {
		NSData *data = [self dataForScreenshot];
		if (data) {
#			if TARGET_OS_IPHONE
			return [[UIImage imageWithData:data] retain];
#			elif TARGET_OS_MAC
			return [[NSImage alloc] initWithData:data];
#			endif
		}
	}
	return nil;
}

- (BOOL)hasScreenshot {
	if (screenshotFilename) {
		return YES;
	} else if (screenshot) {
		return YES;
	} else {
		return NO;
	}
}

- (NSData *)dataForScreenshot {
	NSData *result = nil;
	if (![self hasScreenshot]) {
		return result;
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	if (screenshotFilename && [fm fileExistsAtPath:[self fullPathForScreenshotFilename:screenshotFilename]]) {
		result = [NSData dataWithContentsOfFile:[self fullPathForScreenshotFilename:screenshotFilename]];
	} else if (screenshot) {
#		if TARGET_OS_IPHONE
		result = UIImagePNGRepresentation(screenshot);
#		elif TARGET_OS_MAC
		result = [ATUtilities pngRepresentationOfImage:screenshot];
#		endif
	}
	return result;
}
@end


@implementation ATFeedback (Private)
- (void)setup {
	if (!extraData) {
		extraData = [[NSMutableDictionary alloc] init];
	}
	self.type = ATFeedbackTypeFeedback;
}

- (ATFeedbackType)feedbackTypeFromString:(NSString *)feedbackString {
	if ([feedbackString isEqualToString:@"feedback"] || [feedbackString isEqualToString:@"suggestion"]) {
		return ATFeedbackTypeFeedback;
	} else if ([feedbackString isEqualToString:@"question"]) {
		return ATFeedbackTypeQuestion;
	} else if ([feedbackString isEqualToString:@"praise"]) {
		return ATFeedbackTypePraise;
	} else if ([feedbackString isEqualToString:@"bug"]) {
		return ATFeedbackTypeBug;
	}
	return ATFeedbackTypeFeedback;
}

- (NSString *)stringForFeedbackType:(ATFeedbackType)feedbackType {
	NSString *result = nil;
	switch (feedbackType) {
		case ATFeedbackTypeBug:
			result = @"bug";
			break;
		case ATFeedbackTypePraise:
			result = @"praise";
			break;
		case ATFeedbackTypeQuestion:
			result = @"question";
			break;
		case ATFeedbackTypeFeedback:
		default:
			result = @"feedback";
			break;
	}
	return result;
}

- (NSString *)stringForSource:(ATFeedbackSource)aSource {
	NSString *result = nil;
	switch (aSource) {
		case ATFeedbackSourceEnjoymentDialog:
			result = @"enjoyment_dialog";
			break;
		default:
			break;
	}
	return result;
}

- (NSString *)fullPathForScreenshotFilename:(NSString *)filename {
	return [[[ATBackend sharedBackend] attachmentDirectoryPath] stringByAppendingPathComponent:filename];
}

- (void)createScreenshotSidecarIfNecessary {
	if (screenshot) {
		if (!screenshotFilename) {
			// First time this screenshot has been saved.
			screenshotFilename = [[ATUtilities randomStringOfLength:20] retain];
			NSString *fullPath = [self fullPathForScreenshotFilename:screenshotFilename];
			NSData *screenshotData = [self dataForScreenshot];
			if (![screenshotData writeToFile:fullPath atomically:YES]) {
				ATLogError(@"Unable to save screenshot data to path: %@", fullPath);
			}
		}
	}
}

- (void)deleteScreenshotSidecar {
	if (screenshotFilename) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *fullPath = [self fullPathForScreenshotFilename:screenshotFilename];
		NSError *error = nil;
		if (![fm removeItemAtPath:fullPath error:&error]) {
			ATLogError(@"Error removing screenshot at path: %@. %@", screenshotFilename, error);
			return;
		}
		[screenshotFilename release], screenshotFilename = nil;
	}	
}
@end
