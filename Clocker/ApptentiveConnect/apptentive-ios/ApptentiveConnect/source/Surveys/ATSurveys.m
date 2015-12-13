//
//  ATSurveys.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveys.h"
#import "ATSurveysBackend.h"

NSString *const ATSurveyNewSurveyAvailableNotification = @"ATSurveyNewSurveyAvailableNotification";
NSString *const ATSurveySentNotification = @"ATSurveySentNotification";

NSString *const ATSurveyIDKey = @"ATSurveyIDKey";

@interface ATSurveys ()
+ (ATSurveys *)sharedSurveys;
@end

@implementation ATSurveys
+ (ATSurveys *)sharedSurveys {
	static ATSurveys *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ATSurveys alloc] init];
	});
	return sharedSingleton;
}

+ (BOOL)hasSurveyAvailable {
	return [[ATSurveysBackend sharedBackend] hasSurveyAvailableWithNoTags];
}

+ (BOOL)hasSurveyAvailableWithTags:(NSSet *)tags {
	return [[ATSurveysBackend sharedBackend] hasSurveyAvailableWithTags:tags];
}

+ (void)checkForAvailableSurveys {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend checkForAvailableSurveys];
}

+ (void)presentSurveyControllerFromViewController:(UIViewController *)viewController {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend presentSurveyControllerWithNoTagsFromViewController:viewController];
}

+ (void)presentSurveyControllerWithTags:(NSSet *)tags fromViewController:(UIViewController *)viewController {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend presentSurveyControllerWithTags:tags fromViewController:viewController];
}
@end
