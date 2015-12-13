//
//  ApptentiveMetrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetrics.h"
#import "ATLog.h"
#import "ATAppConfigurationUpdater.h"
#import "ATFeedbackMetrics.h"
#import "ATAppRatingMetrics.h"
#import "ATMetric.h"
#import "ATRecordTask.h"
#import "ATSurveyMetrics.h"
#import "ATTaskQueue.h"

static NSString *ATMetricNameEnjoymentDialogLaunch = @"enjoyment_dialog.launch";
static NSString *ATMetricNameEnjoymentDialogYes = @"enjoyment_dialog.yes";
static NSString *ATMetricNameEnjoymentDialogNo = @"enjoyment_dialog.no";

static NSString *ATMetricNameRatingDialogLaunch = @"rating_dialog.launch";
static NSString *ATMetricNameRatingDialogRate = @"rating_dialog.rate";
static NSString *ATMetricNameRatingDialogRemind = @"rating_dialog.remind";
static NSString *ATMetricNameRatingDialogDecline = @"rating_dialog.decline";

static NSString *ATMetricNameFeedbackDialogLaunch = @"feedback_dialog.launch";
static NSString *ATMetricNameFeedbackDialogCancel = @"feedback_dialog.cancel";
static NSString *ATMetricNameFeedbackDialogSubmit = @"feedback_dialog.submit";

static NSString *ATMetricNameSurveyLaunch = @"survey.launch";
static NSString *ATMetricNameSurveyCancel = @"survey.cancel";
static NSString *ATMetricNameSurveySubmit = @"survey.submit";
static NSString *ATMetricNameSurveyAnswerQuestion = @"survey.question_response";

static NSString *ATMetricNameAppLaunch = @"app.launch";
static NSString *ATMetricNameAppExit = @"app.exit";

@interface ApptentiveMetrics (Private)
- (void)addLaunchMetric;
- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo;
- (ATFeedbackWindowType)windowTypeFromNotification:(NSNotification *)notification;
- (void)feedbackDidShowWindow:(NSNotification *)notification;
- (void)feedbackDidHideWindow:(NSNotification *)notification;

- (ATAppRatingEnjoymentButtonType)appEnjoymentButtonTypeFromNotification:(NSNotification *)notification;
- (void)ratingDidShowEnjoyment:(NSNotification *)notification;
- (void)ratingDidClickEnjoyment:(NSNotification *)notification;

- (ATAppRatingButtonType)appRatingButtonTypeFromNotification:(NSNotification *)notification;
- (void)ratingDidShowRating:(NSNotification *)notification;
- (void)ratingDidClickRating:(NSNotification *)notification;

- (ATSurveyEvent)surveyEventTypeFromNotification:(NSNotification *)notification;
- (void)surveyDidShow:(NSNotification *)notification;
- (void)surveyDidHide:(NSNotification *)notification;
- (void)surveyDidAnswerQuestion:(NSNotification *)notification;

- (void)appWillTerminate:(NSNotification *)notification;
- (void)appDidEnterBackground:(NSNotification *)notification;
- (void)appWillEnterForeground:(NSNotification *)notification;

- (void)preferencesChanged:(NSNotification *)notification;

- (void)updateWithCurrentPreferences;
@end

@implementation ApptentiveMetrics

+ (ApptentiveMetrics *)sharedMetrics {
	static ApptentiveMetrics *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ApptentiveMetrics alloc] init];
	});
	return sharedSingleton;
}

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences = 
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithBool:YES], ATAppConfigurationMetricsEnabledPreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

- (id)init {
	self = [super init];
	if (self) {
		metricsEnabled = NO;
		[ApptentiveMetrics registerDefaults];
		[self updateWithCurrentPreferences];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackDidShowWindow:) name:ATFeedbackDidShowWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackDidHideWindow:) name:ATFeedbackDidHideWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidShowEnjoyment:) name:ATAppRatingDidPromptForEnjoymentNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidClickEnjoyment:) name:ATAppRatingDidClickEnjoymentButtonNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidShowRating:) name:ATAppRatingDidPromptForRatingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidClickRating:) name:ATAppRatingDidClickRatingButtonNotification object:nil];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidShow:) name:ATSurveyDidShowWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidHide:) name:ATSurveyDidHideWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidAnswerQuestion:) name:ATSurveyDidAnswerQuestionNotification object:nil];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:ATConfigurationPreferencesChangedNotification object:nil];
		
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#elif TARGET_OS_MAC
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
		
#endif
		[self performSelector:@selector(addLaunchMetric) withObject:nil afterDelay:0.1];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end



@implementation ApptentiveMetrics (Private)
- (void)addLaunchMetric {
	@autoreleasepool {
		[self addMetricWithName:ATMetricNameAppLaunch info:nil];
	}
}

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo {
	if (metricsEnabled == NO) {
		return;
	}
	ATMetric *metric = [[ATMetric alloc] init];
	metric.name = name;
	[metric addEntriesFromDictionary:userInfo];
	ATRecordTask *task = [[ATRecordTask alloc] init];
	[task setRecord:metric];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[metric release], metric = nil;
	[task release], task = nil;
}

- (ATFeedbackWindowType)windowTypeFromNotification:(NSNotification *)notification {
	ATFeedbackWindowType windowType = ATFeedbackWindowTypeFeedback;
	if ([[notification userInfo] objectForKey:ATFeedbackWindowTypeKey]) {
		windowType = [(NSNumber *)[[notification userInfo] objectForKey:ATFeedbackWindowTypeKey] intValue];
	}
	if (windowType != ATFeedbackWindowTypeFeedback && windowType != ATFeedbackWindowTypeInfo) {
		ATLogError(@"Unknown window type: %d", windowType);
	}
	return windowType;
}

- (void)feedbackDidShowWindow:(NSNotification *)notification {
	NSString *name = nil;
	ATFeedbackWindowType windowType = [self windowTypeFromNotification:notification];
	
	if (windowType == ATFeedbackWindowTypeFeedback) {
		name = ATMetricNameFeedbackDialogLaunch;
	} else if (windowType == ATFeedbackWindowTypeInfo) {
		name = nil;
	}
	
	if (name != nil) {
		[self addMetricWithName:name info:nil];
	}
}

- (void)feedbackDidHideWindow:(NSNotification *)notification {
	ATFeedbackWindowType windowType = [self windowTypeFromNotification:notification];
	ATFeedbackEvent event = ATFeedbackEventTappedCancel;
	if ([[notification userInfo] objectForKey:ATFeedbackWindowHideEventKey]) {
		event = [(NSNumber *)[[notification userInfo] objectForKey:ATFeedbackWindowHideEventKey] intValue];
	}
	
	if (windowType == ATFeedbackWindowTypeFeedback) {
		if (event == ATFeedbackEventTappedCancel) {
			[self addMetricWithName:ATMetricNameFeedbackDialogCancel info:nil];
		} else if (event == ATFeedbackEventTappedSend) {
			[self addMetricWithName:ATMetricNameFeedbackDialogSubmit info:nil];
		}
	} else if (windowType == ATFeedbackWindowTypeInfo) {
		// pass, for now
	}
}

- (ATAppRatingEnjoymentButtonType)appEnjoymentButtonTypeFromNotification:(NSNotification *)notification {
	ATAppRatingEnjoymentButtonType buttonType = ATAppRatingEnjoymentButtonTypeUnknown;
	if ([[notification userInfo] objectForKey:ATAppRatingButtonTypeKey]) {
		buttonType = [(NSNumber *)[[notification userInfo] objectForKey:ATAppRatingButtonTypeKey] intValue];
	}
	if (buttonType != ATAppRatingEnjoymentButtonTypeYes && buttonType != ATAppRatingEnjoymentButtonTypeNo) {
		ATLogError(@"Unknown button type: %d", buttonType);
	}
	return buttonType;
}

- (void)ratingDidShowEnjoyment:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameEnjoymentDialogLaunch info:nil];
}

- (void)ratingDidClickEnjoyment:(NSNotification *)notification {
	ATAppRatingEnjoymentButtonType buttonType = [self appEnjoymentButtonTypeFromNotification:notification];
	if (buttonType == ATAppRatingEnjoymentButtonTypeYes) {
		[self addMetricWithName:ATMetricNameEnjoymentDialogYes info:nil];
	} else if (buttonType == ATAppRatingEnjoymentButtonTypeNo) {
		[self addMetricWithName:ATMetricNameEnjoymentDialogNo info:nil];
	}
}

- (ATAppRatingButtonType)appRatingButtonTypeFromNotification:(NSNotification *)notification {
	ATAppRatingButtonType buttonType = ATAppRatingButtonTypeUnknown;
	if ([[notification userInfo] objectForKey:ATAppRatingButtonTypeKey]) {
		buttonType = [(NSNumber *)[[notification userInfo] objectForKey:ATAppRatingButtonTypeKey] intValue];
	}
	if (buttonType != ATAppRatingButtonTypeNo && buttonType != ATAppRatingButtonTypeRemind && buttonType != ATAppRatingButtonTypeRateApp) {
		ATLogError(@"Unknown button type: %d", buttonType);
	}
	return buttonType;
}

- (void)ratingDidShowRating:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameRatingDialogLaunch info:nil];
}

- (void)ratingDidClickRating:(NSNotification *)notification {
	ATAppRatingButtonType buttonType = [self appRatingButtonTypeFromNotification:notification];
	NSString *name = nil;
	if (buttonType == ATAppRatingButtonTypeNo) {
		name = ATMetricNameRatingDialogDecline;
	} else if (buttonType == ATAppRatingButtonTypeRateApp) {
		name = ATMetricNameRatingDialogRate;
	} else if (buttonType == ATAppRatingButtonTypeRemind) {
		name = ATMetricNameRatingDialogRemind;
	}
	if (name != nil) {
		[self addMetricWithName:name info:nil];
	}
}

- (ATSurveyEvent)surveyEventTypeFromNotification:(NSNotification *)notification {
	ATSurveyEvent event = ATSurveyEventUnknown;
	if ([[notification userInfo] objectForKey:ATSurveyMetricsEventKey]) {
		event = [(NSNumber *)[[notification userInfo] objectForKey:ATSurveyMetricsEventKey] intValue];
	}
	if (event != ATSurveyEventTappedSend && event != ATSurveyEventTappedCancel && event != ATSurveyEventAnsweredQuestion) {
		event = ATSurveyEventUnknown;
		ATLogError(@"Unknown survey event type: %d", event);
	}
	return event;
}

- (void)surveyDidShow:(NSNotification *)notification {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	NSString *surveyID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyIDKey];
	if (surveyID != nil) {
		[info setObject:surveyID forKey:@"id"];
	}
	[self addMetricWithName:ATMetricNameSurveyLaunch info:info];
	[info release], info = nil;
}

- (void)surveyDidHide:(NSNotification *)notification {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	NSString *surveyID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyIDKey];
	if (surveyID != nil) {
		[info setObject:surveyID forKey:@"id"];
	}
	ATSurveyEvent eventType = [self surveyEventTypeFromNotification:notification];
	
	if (eventType == ATSurveyEventTappedSend) {
		[self addMetricWithName:ATMetricNameSurveySubmit info:info];
	} else if (eventType == ATSurveyEventTappedCancel) {
		[self addMetricWithName:ATMetricNameSurveyCancel info:info];
	}
	
	[info release], info = nil;
}

- (void)surveyDidAnswerQuestion:(NSNotification *)notification {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	NSString *surveyID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyIDKey];
	NSString *questionID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyQuestionIDKey];
	if (surveyID != nil) {
		[info setObject:surveyID forKey:@"survey_id"];
	}
	if (questionID != nil) {
		[info setObject:questionID forKey:@"id"];
	}
	ATSurveyEvent eventType = [self surveyEventTypeFromNotification:notification];
	if (eventType == ATSurveyEventAnsweredQuestion) {
		[self addMetricWithName:ATMetricNameSurveyAnswerQuestion info:info];
	}
	
	[info release], info = nil;
}

- (void)appWillTerminate:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameAppExit info:nil];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameAppExit info:nil];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameAppLaunch info:nil];
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self updateWithCurrentPreferences];
}

- (void)updateWithCurrentPreferences {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSNumber *enabled = [defaults objectForKey:ATAppConfigurationMetricsEnabledPreferenceKey];
	if (enabled) {
		metricsEnabled = [enabled boolValue];
	}
}
@end
