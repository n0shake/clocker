//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATAppRatingFlow_Private.h"
#import "ATLog.h"
#import "ATContactStorage.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "PJSONKit.h"

NSString *const ATConfigurationPreferencesChangedNotification = @"ATConfigurationPreferencesChangedNotification";
NSString *const ATAppConfigurationLastUpdatePreferenceKey = @"ATAppConfigurationLastUpdatePreferenceKey";
NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
NSString *const ATAppConfigurationMetricsEnabledPreferenceKey = @"ATAppConfigurationMetricsEnabledPreferenceKey";

// Interval, in seconds, after which we'll update the configuration.
#if APPTENTIVE_DEBUG
#define kATAppConfigurationUpdateInterval (3)
#else
#define kATAppConfigurationUpdateInterval (60*60*24)
#endif


@interface ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration;
@end

@implementation ATAppConfigurationUpdater
+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences = 
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATAppConfigurationLastUpdatePreferenceKey,
	 [NSNumber numberWithBool:YES], ATAppConfigurationMetricsEnabledPreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldCheckForUpdate {
	[ATAppConfigurationUpdater registerDefaults];	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastCheck = [defaults objectForKey:ATAppConfigurationLastUpdatePreferenceKey];
	
#ifndef APPTENTIVE_DEBUG
	NSDate *expiration = [defaults objectForKey:ATAppConfigurationExpirationPreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			return NO;
		}
	}
#endif
	
	// Fall back to the defaults.
	NSTimeInterval interval = [lastCheck timeIntervalSinceNow];
	
	if (interval <= -kATAppConfigurationUpdateInterval) {
		return YES;
	} else {
		return NO;
	}
}


- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)update {
	[self cancel];
	request = [[[ATWebClient sharedClient] requestForGettingAppConfiguration] retain];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
			[delegate configurationUpdaterDidFinish:YES];
		} else {
			ATLogError(@"App configuration result is not NSDictionary!");
			[delegate configurationUpdaterDidFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate configurationUpdaterDidFinish:NO];
	}
}
@end

@implementation ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonConfiguration {
	BOOL hasConfigurationChanges = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[ATAppConfigurationUpdater registerDefaults];
	[ATAppRatingFlow_Private registerDefaults];
	[defaults setObject:[NSDate date] forKey:ATAppConfigurationLastUpdatePreferenceKey];
	[defaults synchronize];
	
	NSDictionary *numberObjects = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 @"ratings_clear_on_upgrade", ATAppRatingClearCountsOnUpgradePreferenceKey, 
		 @"ratings_enabled", ATAppRatingEnabledPreferenceKey,
		 @"ratings_days_before_prompt", ATAppRatingDaysBeforePromptPreferenceKey, 
		 @"ratings_days_between_prompts", ATAppRatingDaysBetweenPromptsPreferenceKey, 
		 @"ratings_events_before_prompt", ATAppRatingSignificantEventsBeforePromptPreferenceKey, 
		 @"ratings_uses_before_prompt", ATAppRatingUsesBeforePromptPreferenceKey, 
		 @"metrics_enabled", ATAppConfigurationMetricsEnabledPreferenceKey,
		 nil];
	
	NSArray *boolPreferences = [NSArray arrayWithObjects:@"ratings_clear_on_upgrade", @"ratings_enabled", @"metrics_enabled", nil];
	NSObject *ratingsPromptLogic = [jsonConfiguration objectForKey:@"ratings_prompt_logic"];
	
	for (NSString *key in numberObjects) {
		NSObject *value = [jsonConfiguration objectForKey:[numberObjects objectForKey:key]];
		if (!value || ![value isKindOfClass:[NSNumber class]]) {
			continue;
		}
		
		NSNumber *numberValue = (NSNumber *)value;
		
		NSNumber *existingNumber = [defaults objectForKey:key];
		if ([existingNumber isEqualToNumber:numberValue]) {
			continue;
		}
		
		if ([boolPreferences containsObject:[numberObjects objectForKey:key]]) {
			[defaults setObject:numberValue forKey:key];
		} else {
			NSUInteger unsignedIntegerValue = [numberValue unsignedIntegerValue];
			NSNumber *replacementValue = [NSNumber numberWithUnsignedInteger:unsignedIntegerValue];
			
			[defaults setObject:replacementValue forKey:key];
		}
		hasConfigurationChanges = YES;
	}
	
	if (ratingsPromptLogic) {
		NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:ratingsPromptLogic withPredicateInfo:nil];
		if (predicate) {
			[defaults setObject:ratingsPromptLogic forKey:ATAppRatingPromptLogicPreferenceKey];
			hasConfigurationChanges = YES;
		}
	}
	
	if ([jsonConfiguration objectForKey:@"review_url"]) {
		NSString *reviewURLString = [jsonConfiguration objectForKey:@"review_url"];
		[defaults setObject:reviewURLString forKey:ATAppRatingReviewURLPreferenceKey];
	}
	
	if ([jsonConfiguration objectForKey:@"cache-expiration"]) {
		NSString *expirationDateString = [jsonConfiguration objectForKey:@"cache-expiration"];
		NSDate *expirationDate = [ATUtilities dateFromISO8601String:expirationDateString];
		if (expirationDate) {
			[defaults setObject:expirationDate forKey:ATAppConfigurationExpirationPreferenceKey];
		}
	}
	
	if (hasConfigurationChanges) {
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingSettingsAreFromServerPreferenceKey];
		[defaults synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:nil];
	}
}
@end

