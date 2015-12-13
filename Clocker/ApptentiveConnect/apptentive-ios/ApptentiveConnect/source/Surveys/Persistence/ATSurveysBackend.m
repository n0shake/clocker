//
//  ATSurveysBackend.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveysBackend.h"
#import "ATBackend.h"
#import "ATSurvey.h"
#import "ATSurveyGetSurveysTask.h"
#import "ATSurveyMetrics.h"
#import "ATSurveys.h"
#import "ATSurveyParser.h"
#import "ATSurveyViewController.h"
#import "ATTaskQueue.h"
#import "PJSONKit.h"

NSString *const ATSurveySentSurveysPreferenceKey = @"ATSurveySentSurveysPreferenceKey";
NSString *const ATSurveyCachedSurveysExpirationPreferenceKey = @"ATSurveyCachedSurveysExpirationPreferenceKey";

@interface ATSurveysBackend ()
+ (NSString *)cachedSurveysStoragePath;
- (BOOL)shouldRetrieveNewSurveys;
- (void)presentSurveyControllerFromViewControllerWithCurrentSurvey:(UIViewController *)viewController;
- (ATSurvey *)surveyWithTags:(NSSet *)tags;
@end

@implementation ATSurveysBackend

+ (ATSurveysBackend *)sharedBackend {
	static ATSurveysBackend *sharedBackend = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *defaultPreferences = [NSDictionary dictionaryWithObject:[NSArray array] forKey:ATSurveySentSurveysPreferenceKey];
		[defaults registerDefaults:defaultPreferences];
		
		sharedBackend = [[ATSurveysBackend alloc] init];
	});
	return sharedBackend;
}

+ (NSString *)cachedSurveysStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"cachedsurveys.objects"];
}

- (id)init {
	if ((self = [super init])) {
		availableSurveys = [[NSMutableArray alloc] init];
		NSFileManager *fm = [NSFileManager defaultManager];
		if ([fm fileExistsAtPath:[ATSurveysBackend cachedSurveysStoragePath]]) {
			@try {
				NSArray *surveys = [NSKeyedUnarchiver unarchiveObjectWithFile:[ATSurveysBackend cachedSurveysStoragePath]];
				[availableSurveys addObjectsFromArray:surveys];
			} @catch (NSException *exception) {
				ATLogError(@"Unable to unarchive surveys: %@", exception);
			}
		}
	}
	return self;
}

- (void)dealloc {
	[availableSurveys release], availableSurveys = nil;
	[super dealloc];
}

- (BOOL)shouldRetrieveNewSurveys {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *expiration = [defaults objectForKey:ATSurveyCachedSurveysExpirationPreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			NSFileManager *fm = [NSFileManager defaultManager];
			if (![fm fileExistsAtPath:[ATSurveysBackend cachedSurveysStoragePath]]) {
				// If no file, check anyway.
				return YES;
			}
			return NO;
		}
	} else {
		return YES;
	}
}

- (void)checkForAvailableSurveys {
	if ([self shouldRetrieveNewSurveys]) {
		ATSurveyGetSurveysTask *task = [[ATSurveyGetSurveysTask alloc] init];
		[[ATTaskQueue sharedTaskQueue] addTask:task];
		[task release], task = nil;
	}
}

- (ATSurvey *)currentSurvey {
	return currentSurvey;
}

- (void)resetSurvey {
	@synchronized(self) {
		[currentSurvey reset];
		[currentSurvey release], currentSurvey = nil;
	}
}

- (void)presentSurveyControllerFromViewControllerWithCurrentSurvey:(UIViewController *)viewController {
	ATSurveyViewController *vc = [[ATSurveyViewController alloc] initWithSurvey:currentSurvey];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[viewController presentModalViewController:nc animated:YES];
	} else {
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		[viewController presentModalViewController:nc animated:YES];
	}
	[nc release];
	[vc release];
	
	NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:currentSurvey.identifier, ATSurveyMetricsSurveyIDKey, [NSNumber numberWithInt:ATSurveyWindowTypeSurvey], ATSurveyWindowTypeKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidShowWindowNotification object:nil userInfo:metricsInfo];
	[metricsInfo release], metricsInfo = nil;
}

- (void)presentSurveyControllerWithNoTagsFromViewController:(UIViewController *)viewController {
	if (currentSurvey != nil) {
		[self resetSurvey];
	}
	currentSurvey = [[self surveyWithNoTags] retain];
	if (currentSurvey == nil) {
		return;
	}
	[self presentSurveyControllerFromViewControllerWithCurrentSurvey:viewController];
}

- (void)presentSurveyControllerWithTags:(NSSet *)tags fromViewController:(UIViewController *)viewController {
	if (currentSurvey != nil) {
		[self resetSurvey];
	}
	currentSurvey = [[self surveyWithTags:tags] retain];
	if (currentSurvey == nil) {
		return;
	}
	[self presentSurveyControllerFromViewControllerWithCurrentSurvey:viewController];
}

- (void)setDidSendSurvey:(ATSurvey *)survey {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *sentSurveys = [defaults objectForKey:ATSurveySentSurveysPreferenceKey];
	if (![sentSurveys containsObject:survey.identifier]) {
		NSMutableArray *replacementSurveys = [sentSurveys mutableCopy];
		[replacementSurveys addObject:survey.identifier];
		[defaults setObject:replacementSurveys forKey:ATSurveySentSurveysPreferenceKey];
		[defaults synchronize];
		[replacementSurveys release], replacementSurveys = nil;
	}
}

- (ATSurvey *)surveyWithNoTags {
	ATSurvey *result = nil;
	@synchronized(self) {
		for (ATSurvey *survey in availableSurveys) {
			if ([survey surveyHasNoTags]) {
				if (![self surveyAlreadySubmitted:survey]) {
					result = survey;
				} else if (![survey multipleResponsesAllowed] || ![survey isActive]) {
					continue;
				} else {
					result = survey;
				}
			}
		}
	}
	return result;
}

- (ATSurvey *)surveyWithTags:(NSSet *)tags {
	ATSurvey *result = nil;
	@synchronized(self) {
		for (ATSurvey *survey in availableSurveys) {
			if ([survey surveyHasTags:tags]) {
				if (![self surveyAlreadySubmitted:survey]) {
					result = survey;
					break;
				} else if (![survey multipleResponsesAllowed] || ![survey isActive]) {
					continue;
				} else {
					result = survey;
				}
			}
		}
	}
	return result;
}

- (BOOL)hasSurveyAvailableWithNoTags {
	ATSurvey *survey = [self surveyWithNoTags];
	if (survey) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)hasSurveyAvailableWithTags:(NSSet *)tags {
	ATSurvey *survey = [self surveyWithTags:tags];
	if (survey) {
		return YES;
	} else {
		return NO;
	}
}
@end


@implementation ATSurveysBackend (Private)
- (BOOL)surveyAlreadySubmitted:(ATSurvey *)survey {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL sentSurvey = NO;
	if ([[defaults objectForKey:ATSurveySentSurveysPreferenceKey] containsObject:survey.identifier]) {
		sentSurvey = YES;
	}
	return sentSurvey;
}

- (void)didReceiveNewSurveys:(NSArray *)surveys maxAge:(NSTimeInterval)expiresMaxAge {
	BOOL hasNewSurvey = NO;
	for (ATSurvey *survey in surveys) {
		if (![self surveyAlreadySubmitted:survey]) {
			hasNewSurvey = YES;
		}
	}
	
	@synchronized(self) {
		[NSKeyedArchiver archiveRootObject:surveys toFile:[ATSurveysBackend cachedSurveysStoragePath]];
		// Store expiration.
		if (expiresMaxAge > 0) {
			NSDate *date = [NSDate dateWithTimeInterval:expiresMaxAge sinceDate:[NSDate date]];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:date forKey:ATSurveyCachedSurveysExpirationPreferenceKey];
			[defaults synchronize];
		}
		
		[availableSurveys removeAllObjects];
		[availableSurveys addObjectsFromArray:surveys];
	}
	
	if (hasNewSurvey) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyNewSurveyAvailableNotification object:nil];
	}
}
@end
