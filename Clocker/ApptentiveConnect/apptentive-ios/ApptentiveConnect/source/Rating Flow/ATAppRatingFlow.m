//
//  ATAppRatingFlow.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"
#import "ATLog.h"
#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATAppConfigurationUpdater.h"
#import "ATFeedback.h"
#import "ATReachability.h"
#import "ATAppRatingMetrics.h"
#import "ATAppRatingFlow_Private.h"
#import "ATUtilities.h"
#import "ATWebClient.h"


NSString *const ATAppRatingFlowUserAgreedToRateAppNotification = @"ATAppRatingFlowUserAgreedToRateAppNotification";

// Don't count an app re-launch within 20 seconds as
// an app launch.
#define kATAppAppUsageMinimumInterval (20)

#if TARGET_OS_IPHONE
@interface ATAppRatingFlow ()
@property (nonatomic, retain) UIViewController *viewController;
@end
#endif

@interface ATAppRatingFlow ()
/* Days since first app use when the user will first be prompted. */
@property (nonatomic, readonly) NSUInteger daysBeforePrompt;

/* Number of app uses before which the user will first be prompted. */
@property (nonatomic, readonly) NSUInteger usesBeforePrompt;

/* Significant events before the user will be prompted. */
@property (nonatomic, readonly) NSUInteger significantEventsBeforePrompt;

/* Days before the user will be re-prompted after having pressed the "Remind Me Later" button. */
@property (nonatomic, readonly) NSUInteger daysBeforeRePrompting;
@end


@interface ATAppRatingFlow (Private)
- (void)updateLastUseOfApp;
- (void)postNotification:(NSString *)name;
- (void)postNotification:(NSString *)name forButton:(int)button;
- (NSURL *)URLForRatingApp;
- (void)openURLForRatingApp;
- (BOOL)requirementsToShowDialogMet;
- (BOOL)shouldShowDialog;
/*! Returns YES if a dialog was shown. */
- (BOOL)showDialogIfNecessary;
- (void)updateVersionInfo;
- (void)userDidUseApp;
- (void)userDidSignificantEvent;
- (void)incrementPromptCount;
- (void)setRatingDialogWasShown;
- (void)setUserDislikesThisVersion;
- (void)setDeclinedToRateThisVersion;
- (void)setRatedApp:(BOOL)hasRated;
- (void)logDefaults;

#if TARGET_OS_IPHONE
- (void)appDidFinishLaunching:(NSNotification *)notification;
- (void)appDidEnterBackground:(NSNotification *)notification;
- (void)appWillEnterForeground:(NSNotification *)notification;
- (void)appWillResignActive:(NSNotification *)notification;

- (UIViewController *)rootViewControllerForCurrentWindow;
#endif
- (void)tryToShowDialogWaitingForReachability;
- (void)reachabilityChangedAndPendingDialog:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)loadPreferences;
@end


@implementation ATAppRatingFlow
@synthesize daysBeforePrompt, usesBeforePrompt, significantEventsBeforePrompt, daysBeforeRePrompting;
#if TARGET_OS_IPHONE
@synthesize viewController;
#endif

- (id)initWithAppID:(NSString *)anITunesAppID {
	if ((self = [super init])) {
		[ATAppRatingFlow_Private registerDefaults];
		[self loadPreferences];
		iTunesAppID = [anITunesAppID retain];
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
#endif
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:ATConfigurationPreferencesChangedNotification object:nil];
	}
	return self;
}

+ (ATAppRatingFlow *)sharedRatingFlowWithAppID:(NSString *)iTunesAppID {
	static ATAppRatingFlow *sharedRatingFlow = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedRatingFlow = [[ATAppRatingFlow alloc] initWithAppID:iTunesAppID];
	});
	return sharedRatingFlow;
}

#if TARGET_OS_IPHONE
- (void)appDidLaunch:(BOOL)canPromptForRating viewController:(UIViewController *)vc 
#elif TARGET_OS_MAC
- (void)appDidLaunch:(BOOL)canPromptForRating
#endif
{
#if TARGET_OS_IPHONE
	self.viewController = vc;
#endif

#if TARGET_IPHONE_SIMULATOR
	[self logDefaults];
#endif
	[self userDidUseApp];
	BOOL showedDialog = NO;
	if (canPromptForRating) {
		showedDialog = [self showDialogIfNecessary];
	}
#if TARGET_OS_IPHONE
	if (!showedDialog) {
		self.viewController = nil;
	}
#endif
}

#if TARGET_OS_IPHONE
- (void)appDidEnterForeground:(BOOL)canPromptForRating viewController:(UIViewController *)vc {
	self.viewController = vc;
	[self userDidUseApp];
	
	BOOL showedDialog = NO;
	if (canPromptForRating) {
		showedDialog = [self showDialogIfNecessary];
	}
	
	if (!showedDialog) {
		self.viewController = nil;
	}
}
#endif

#if TARGET_OS_IPHONE
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating viewController:(UIViewController *)vc
#elif TARGET_OS_MAC
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating
#endif
{
#if TARGET_OS_IPHONE
	self.viewController = vc;
#endif
	[self userDidSignificantEvent];

#if TARGET_OS_IPHONE
	if (!showedDialog) {
		self.viewController = nil;
	}
#endif
}

#if TARGET_OS_IPHONE
- (void)showEnjoymentDialog:(UIViewController *)vc
#elif TARGET_OS_MAC
- (IBAction)showEnjoymentDialog:(id)sender
#endif
{
	NSString *title = [NSString stringWithFormat:ATLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [self appName]];
#if TARGET_OS_IPHONE
	self.viewController = vc;
	if (!enjoymentDialog) {
		enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"No", @"no"), ATLocalizedString(@"Yes", @"yes"), nil];
		[enjoymentDialog show];
	}
	[self postNotification:ATAppRatingDidPromptForEnjoymentNotification];
	[self incrementPromptCount];
	[self setRatingDialogWasShown];
#elif TARGET_OS_MAC
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:ATLocalizedString(@"Yes", @"yes")];
	[alert addButtonWithTitle:ATLocalizedString(@"No", @"no")];
	[alert setMessageText:title];
	[alert setInformativeText:ATLocalizedString(@"You've been using this app for a while. Do you love it?", @"Enjoyment dialog text")];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setIcon:[NSImage imageNamed:NSImageNameApplicationIcon]];
	[self postNotification:ATAppRatingDidPromptForEnjoymentNotification];
	[self incrementPromptCount];
	[self setRatingDialogWasShown];
	NSUInteger result = [alert runModal];
	if (result == NSAlertFirstButtonReturn) { // yes
		[self showRatingDialog:self];
	} else if (result == NSAlertSecondButtonReturn) { // no
		[self setUserDislikesThisVersion];
		
		[[ATBackend sharedBackend] setCurrentFeedback:nil];
		ATConnect *connection = [ATConnect sharedConnection];
		connection.customPlaceholderText = ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
		ATFeedbackControllerType oldType = connection.feedbackControllerType;
		connection.feedbackControllerType = ATFeedbackControllerSimple;
		[connection showFeedbackWindow:self];
		ATFeedback *inProgressFeedback = [[ATBackend sharedBackend] currentFeedback];
		inProgressFeedback.source = ATFeedbackSourceEnjoymentDialog;
		connection.customPlaceholderText = nil;
		connection.feedbackControllerType = oldType;
	}
#endif
}

#if TARGET_OS_IPHONE
- (void)showRatingDialog:(UIViewController *)vc
#elif TARGET_OS_MAC
- (IBAction)showRatingDialog:(id)sender 
#endif
{
	NSString *title = ATLocalizedString(@"Thank You", @"Rate app title.");
	NSString *message = [NSString stringWithFormat:ATLocalizedString(@"We're so happy to hear that you love %@! It'd be really helpful if you rated us in the App Store. Thanks so much for spending some time with us.", @"Rate app message. Parameter is app name."), [self appName]];
	NSString *rateAppTitle = [NSString stringWithFormat:ATLocalizedString(@"Rate %@", @"Rate app button title"), [self appName]];
	NSString *noThanksTitle = ATLocalizedString(@"No Thanks", @"cancel title for app rating dialog");
	NSString *remindMeTitle = ATLocalizedString(@"Remind Me Later", @"Remind me later button title");
#if TARGET_OS_IPHONE
	self.viewController = vc;
	if (!ratingDialog) {
		ratingDialog = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:noThanksTitle otherButtonTitles:rateAppTitle, remindMeTitle, nil];
		[ratingDialog show];
	}
	[self postNotification:ATAppRatingDidPromptForRatingNotification];
	[self setRatingDialogWasShown];
#elif TARGET_OS_MAC
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:noThanksTitle];
	[alert addButtonWithTitle:remindMeTitle];
	[alert addButtonWithTitle:rateAppTitle];
	[alert setMessageText:title];
	[alert setInformativeText:message];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setIcon:[NSImage imageNamed:NSImageNameApplicationIcon]];
	[self postNotification:ATAppRatingDidPromptForRatingNotification];
	[self setRatingDialogWasShown];
	NSUInteger result = [alert runModal];
	if (result == NSAlertFirstButtonReturn) { // cancel
		[self setDeclinedToRateThisVersion];
	} else if (result == NSAlertSecondButtonReturn) { // remind me
		[self setRatingDialogWasShown];
	} else if (result == NSAlertThirdButtonReturn) { // rate app
		[self openURLForRatingApp];
	}
#endif
}

#pragma mark Properties

- (void)setAppName:(NSString *)anAppName {
	if (appName != anAppName) {
		[appName release], appName = nil;
		appName = [anAppName copy];
	}
}

- (NSString *)appName {
	if (appName != nil) {
		return appName;
	}
	NSString *displayName = nil;
	NSArray *appNameKeys = [NSArray arrayWithObjects:@"CFBundleDisplayName", (NSString *)kCFBundleNameKey, nil];
	NSMutableArray *infoDictionaries = [NSMutableArray array];
	if ([[NSBundle mainBundle] localizedInfoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] localizedInfoDictionary]];
	}
	if ([[NSBundle mainBundle] infoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] infoDictionary]];
	}
	for (NSDictionary *infoDictionary in infoDictionaries) {
		if (displayName != nil) {
			break;
		}
		for (NSString *appNameKey in appNameKeys) {
			displayName = [infoDictionary objectForKey:appNameKey];
			if (displayName != nil) {
				break;
			}
		}
	}
	return displayName;
}

#if TARGET_OS_IPHONE
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == enjoymentDialog) {
		[enjoymentDialog release], enjoymentDialog = nil;
		if (buttonIndex == 0) { // no
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeNo];
			[self setUserDislikesThisVersion];
			if (!self.viewController) {
				ATLogError(@"No view controller to present feedback interface!!");
			} else {
				[[ATBackend sharedBackend] setCurrentFeedback:nil];
				ATConnect *connection = [ATConnect sharedConnection];
				connection.customPlaceholderText = ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
				ATFeedbackControllerType oldType = connection.feedbackControllerType;
				connection.feedbackControllerType = ATFeedbackControllerSimple;
				[connection presentFeedbackControllerFromViewController:self.viewController];
				ATFeedback *inProgressFeedback = [[ATBackend sharedBackend] currentFeedback];
				inProgressFeedback.source = ATFeedbackSourceEnjoymentDialog;
				connection.customPlaceholderText = nil;
				self.viewController = nil;
				connection.feedbackControllerType = oldType;
			}
		} else if (buttonIndex == 1) { // yes
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
			[self showRatingDialog:self.viewController];
		}
	} else if (alertView == ratingDialog) {
		[ratingDialog release], ratingDialog = nil;
		if (buttonIndex == 1) { // rate
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRateApp];
			[self openURLForRatingApp];
		} else if (buttonIndex == 2) { // remind later
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRemind];
			[self setRatingDialogWasShown];
		} else if (buttonIndex == 0) { // no thanks
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeNo];
			[self setDeclinedToRateThisVersion];
		}
		self.viewController = nil;
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	ATLogDebug(@"ATAppRatingFlow dismissing alert view %@, %d", alertView, buttonIndex);
	if (alertView == enjoymentDialog) {
		[enjoymentDialog release], enjoymentDialog = nil;
		self.viewController = nil;
	} else if (alertView == ratingDialog) {
		[ratingDialog release], ratingDialog = nil;
		self.viewController = nil;
	}
}

#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)productViewController {
	[productViewController dismissModalViewControllerAnimated:YES];
}
#endif
@end


@implementation ATAppRatingFlow (Private)
- (void)updateLastUseOfApp {
	if (lastUseOfApp) {
		[lastUseOfApp release], lastUseOfApp = nil;
	}
	lastUseOfApp = [[NSDate alloc] init];
}

- (void)postNotification:(NSString *)name {
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (void)postNotification:(NSString *)name forButton:(int)button {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:button] forKey:ATAppRatingButtonTypeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (NSURL *)URLForRatingApp {
	NSString *URLString = nil;
	NSString *URLStringFromPreferences = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppRatingReviewURLPreferenceKey];
	if (URLStringFromPreferences == nil) {
#if TARGET_OS_IPHONE
		NSString *osVersion = [[UIDevice currentDevice] systemVersion];
		if ([ATUtilities versionString:osVersion isGreaterThanVersionString:@"6.0"] || [ATUtilities versionString:osVersion isEqualToVersionString:@"6.0"]) {
			URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode], iTunesAppID];
		} else {
			URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", iTunesAppID];
		}
#elif TARGET_OS_MAC
		URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", iTunesAppID];
#endif
	} else {
		URLString = URLStringFromPreferences;
	}
	return [NSURL URLWithString:URLString];
}

#if TARGET_OS_IPHONE
- (void)showUnableToOpenAppStoreDialog {
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Oops!", @"Unable to load the App Store title") message:ATLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message") delegate:nil cancelButtonTitle:ATLocalizedString(@"Okay", @"Okay button title") otherButtonTitles:nil] autorelease];
	[errorAlert show];
	[self setRatedApp:NO];
}
#endif

- (void)openURLForRatingApp {
	NSURL *url = [self URLForRatingApp];
	[self setRatedApp:YES];
#if TARGET_OS_IPHONE
	if ([SKStoreProductViewController class] != NULL && iTunesAppID) {
#if TARGET_IPHONE_SIMULATOR
		[self showUnableToOpenAppStoreDialog];
#else
		SKStoreProductViewController *vc = [[[SKStoreProductViewController alloc] init] autorelease];
		vc.delegate = self;
		[vc loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:iTunesAppID} completionBlock:^(BOOL result, NSError *error) {
			if (error) {
				[self showUnableToOpenAppStoreDialog];
				ATLogError(@"Error loading product view: %@", error);
			} else {
				UIViewController *presentingVC = [self rootViewControllerForCurrentWindow];
				[presentingVC presentModalViewController:vc animated:YES];
			}
		}];
#endif
	} else {
		if (![[UIApplication sharedApplication] canOpenURL:url]) {
			ATLogError(@"No application can open the URL: %@", url);
			[self showUnableToOpenAppStoreDialog];
		}
		[[UIApplication sharedApplication] openURL:url];
	}
#elif TARGET_OS_MAC
	[[NSWorkspace sharedWorkspace] openURL:url];
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingFlowUserAgreedToRateAppNotification object:nil];
}


- (BOOL)requirementsToShowDialogMet {
	BOOL result = NO;
	
	do { // once
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		// Ratings are disabled, don't show dialog.
		if ([[defaults objectForKey:ATAppRatingEnabledPreferenceKey] boolValue] == NO) {
			break;
		}
		
		// Check to see if the user has rated the app.
		NSNumber *rated = [defaults objectForKey:ATAppRatingFlowRatedAppKey];
		if (rated != nil && [rated boolValue]) {
			break;
		}
		
		// Check to see if the user has rejected rating this version.
		NSNumber *rejected = [defaults objectForKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
		if (rejected != nil && [rejected boolValue]) {
			break;
		}
		
		// Check to see if the user dislikes this version of the app.
		NSNumber *dislikes = [defaults objectForKey:ATAppRatingFlowUserDislikesThisVersionKey];
		if (dislikes != nil && [dislikes boolValue]) {
			break;
		}
		
		// If we don't have the last version set, update it and don't show
		// the dialog.
		NSString *lastBundleVersion = [defaults objectForKey:ATAppRatingFlowLastUsedVersionKey];
		if (lastBundleVersion == nil) {
			[self updateVersionInfo];
			break;
		}
		
		// If the user has been prompted already, make sure we're after the
		// number of days for them to be re-prompted.
		NSDate *lastPrompt = [defaults objectForKey:ATAppRatingFlowLastPromptDateKey];
		if (lastPrompt != nil && self.daysBeforeRePrompting != 0) {
			double nextPromptDouble = [lastPrompt timeIntervalSince1970] + 60*60*24*self.daysBeforeRePrompting;
			if ([[NSDate date] timeIntervalSince1970] < nextPromptDouble) {
				break;
			}
		}
		
		NSInteger promptCount = [[defaults objectForKey:ATAppRatingFlowPromptCountThisVersionKey] integerValue];
		if (self.daysBeforeRePrompting == 0 && promptCount > 0) {
			// Don't prompt more than once.
			break;
		} else if (promptCount > 1) {
			// Don't prompt more than twice per update.
			break;
		}
		
		ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
		info.firstUse = [defaults objectForKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
		info.significantEvents = [[defaults objectForKey:ATAppRatingFlowSignificantEventsCountKey] unsignedIntegerValue];
		info.appUses = [[defaults objectForKey:ATAppRatingFlowUseCountKey] unsignedIntegerValue];
		info.daysBeforePrompt = self.daysBeforePrompt;
		info.significantEventsBeforePrompt = self.significantEventsBeforePrompt;
		info.usesBeforePrompt = self.usesBeforePrompt;
		
		NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[defaults objectForKey:ATAppRatingPromptLogicPreferenceKey] withPredicateInfo:info];
		if (predicate) {
			result = [ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info];
		}
		[info release], info = nil;
	} while (NO);
	
	return result;
}

- (BOOL)shouldShowDialog {
	// No network connection, don't show dialog.
	if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
		return NO;
	}
	return [self requirementsToShowDialogMet];
}

- (BOOL)showDialogIfNecessary {
#if TARGET_OS_IPHONE
	if ([self shouldShowDialog]) {
		[self showEnjoymentDialog:self.viewController];
		return YES;
	} else if ([self rootViewControllerForCurrentWindow]) {
		[self tryToShowDialogWaitingForReachability];
	}
#elif TARGET_OS_MAC
	if ([self shouldShowDialog]) {
		[self showEnjoymentDialog:self];
	} else {
		[self tryToShowDialogWaitingForReachability];
	}
#endif
	return NO;
}

- (void)updateVersionInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *currentBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
	NSString *lastBundleVersion = [defaults objectForKey:ATAppRatingFlowLastUsedVersionKey];
	
	if (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion]) {
		BOOL clearCounts = [(NSNumber *)[defaults objectForKey:ATAppRatingClearCountsOnUpgradePreferenceKey] boolValue];
		if (clearCounts) {
			// Clear the counters.
			[defaults setObject:[NSNumber numberWithUnsignedInteger:0] forKey:ATAppRatingFlowUseCountKey];
			[defaults setObject:[NSNumber numberWithUnsignedInteger:0] forKey:ATAppRatingFlowSignificantEventsCountKey];
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:ATAppRatingFlowRatedAppKey];
		}
		
		[defaults setObject:currentBundleVersion forKey:ATAppRatingFlowLastUsedVersionKey];
		
		[defaults setObject:[NSDate date] forKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:ATAppRatingFlowUserDislikesThisVersionKey];
		[defaults setObject:[NSNumber numberWithInteger:0] forKey:ATAppRatingFlowPromptCountThisVersionKey];
		
		[defaults synchronize];
	}
	
}

- (void)userDidUseApp {
	if (lastUseOfApp != nil) {
		NSTimeInterval interval = [lastUseOfApp timeIntervalSinceNow];
		
		if (interval >= -kATAppAppUsageMinimumInterval) {
			[self updateLastUseOfApp];
			return;
		}
	}
	[self updateLastUseOfApp];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSNumber *useCount = [defaults objectForKey:ATAppRatingFlowUseCountKey];
	NSUInteger count = 0;
	if (useCount != nil) {
		count = [useCount unsignedIntegerValue];
	}
	count++;
	
	[defaults setObject:[NSNumber numberWithUnsignedInteger:count] forKey:ATAppRatingFlowUseCountKey];
	[defaults synchronize];
	
	[self updateVersionInfo];
}

- (void)userDidSignificantEvent {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSNumber *eventCount = [defaults objectForKey:ATAppRatingFlowSignificantEventsCountKey];
	NSUInteger count = 0;
	if (eventCount != nil) {
		count = [eventCount unsignedIntegerValue];
	}
	
	[defaults setObject:[NSNumber numberWithUnsignedInteger:count+1] forKey:ATAppRatingFlowSignificantEventsCountKey];
	[defaults synchronize];
	
}

- (void)incrementPromptCount {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger promptCount = [[defaults objectForKey:ATAppRatingFlowPromptCountThisVersionKey] integerValue];
	promptCount += 1;
	[defaults setObject:[NSNumber numberWithInteger:promptCount] forKey:ATAppRatingFlowPromptCountThisVersionKey];
	[defaults synchronize];
}

- (void)setRatingDialogWasShown {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSDate date] forKey:ATAppRatingFlowLastPromptDateKey];
	[defaults synchronize];
}

- (void)setUserDislikesThisVersion {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingFlowUserDislikesThisVersionKey];
	[defaults synchronize];
}

- (void)setDeclinedToRateThisVersion {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
	[defaults synchronize];
}

- (void)setRatedApp:(BOOL)hasRated {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:hasRated] forKey:ATAppRatingFlowRatedAppKey];
	[defaults synchronize];
}

- (void)logDefaults {
	NSArray *keys = [NSArray arrayWithObjects:ATAppRatingFlowLastUsedVersionKey, ATAppRatingFlowLastUsedVersionFirstUseDateKey, ATAppRatingFlowDeclinedToRateThisVersionKey, ATAppRatingFlowUserDislikesThisVersionKey, ATAppRatingFlowPromptCountThisVersionKey, ATAppRatingFlowLastPromptDateKey, ATAppRatingFlowUseCountKey, ATAppRatingFlowSignificantEventsCountKey, ATAppRatingFlowRatedAppKey, nil];
	ATLogDebug(@"-- BEGIN ATAppRatingFlow DEFAULTS --");
	for (NSString *key in keys) {
		ATLogDebug(@"%@ == %@", key, [[NSUserDefaults standardUserDefaults] objectForKey:key]);
	}
	ATLogDebug(@"-- END ATAppRatingFlow DEFAULTS --");
}

#if TARGET_OS_IPHONE
- (void)appDidFinishLaunching:(NSNotification *)notification {
	[self userDidUseApp];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[self updateLastUseOfApp];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[self userDidUseApp];
}

- (void)appWillResignActive:(NSNotification *)notification {
	[self updateLastUseOfApp];
}

- (void)appWillEnterBackground:(NSNotification *)notification {
	// We want to hide any dialogs here.
	if (enjoymentDialog) {
		[enjoymentDialog dismissWithClickedButtonIndex:3 animated:NO];
	}
	if (ratingDialog) {
		[ratingDialog dismissWithClickedButtonIndex:3 animated:NO];
	}
	[self updateLastUseOfApp];
}


- (UIViewController *)rootViewControllerForCurrentWindow {
	UIWindow *window = nil;
	if (self.viewController && self.viewController.view && self.viewController.view.window) {
		window = self.viewController.view.window;
	} else {
		for (UIWindow *tmpWindow in [[UIApplication sharedApplication] windows]) {
			if ([[tmpWindow screen] isEqual:[UIScreen mainScreen]] && [tmpWindow isKeyWindow]) {
				window = tmpWindow;
				break;
			}
		}
	}
	if (window && [window respondsToSelector:@selector(rootViewController)]) {
		UIViewController *vc = [window rootViewController];
		if ([vc respondsToSelector:@selector(presentedViewController)] && [vc presentedViewController]) {
			return [vc presentedViewController];
		}
		if ([vc respondsToSelector:@selector(modalViewController)] && [vc modalViewController]) {
			return [vc modalViewController];
		}
		return vc;
	} else {
		return nil;
	}
}
#endif

- (void)tryToShowDialogWaitingForReachability {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(tryToShowDialogWaitingForReachability) withObject:nil waitUntilDone:NO];
		return;
	}
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#if TARGET_OS_IPHONE
	UIViewController *vc = [self rootViewControllerForCurrentWindow];
	
	if (vc && [self requirementsToShowDialogMet]) {
		// We can get a root view controller and we should be showing a dialog.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
	}
#elif TARGET_OS_MAC
	if ([self requirementsToShowDialogMet]) {
		// We should show a ratings dialog.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
	}
#endif
	[pool release], pool = nil;
}

- (void)reachabilityChangedAndPendingDialog:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ATReachabilityStatusChanged object:nil];

#if TARGET_OS_IPHONE
	UIViewController *vc = [self rootViewControllerForCurrentWindow];
	
	if (vc && [self requirementsToShowDialogMet]) {
		if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
		} else {
			[self showEnjoymentDialog:vc];
		}
		
	}
#elif TARGET_OS_MAC
	if ([self requirementsToShowDialogMet]) {
		if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
		} else {
			[self showEnjoymentDialog:self];
		}
	}
#endif
	[pool release], pool = nil;
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self loadPreferences];
}

- (void)loadPreferences {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	daysBeforePrompt = [(NSNumber *)[defaults objectForKey:ATAppRatingDaysBeforePromptPreferenceKey] unsignedIntegerValue];
	usesBeforePrompt = [(NSNumber *)[defaults objectForKey:ATAppRatingUsesBeforePromptPreferenceKey] unsignedIntegerValue];
	significantEventsBeforePrompt = [(NSNumber *)[defaults objectForKey:ATAppRatingSignificantEventsBeforePromptPreferenceKey] unsignedIntegerValue];
	daysBeforeRePrompting = [(NSNumber *)[defaults objectForKey:ATAppRatingDaysBetweenPromptsPreferenceKey] unsignedIntegerValue];
}
@end
