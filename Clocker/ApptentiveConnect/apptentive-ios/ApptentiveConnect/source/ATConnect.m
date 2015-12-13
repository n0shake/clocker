//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATConnect.h"
#import "ATBackend.h"
#import "ATContactStorage.h"
#import "ATFeedback.h"
#import "ATUtilities.h"
#if TARGET_OS_IPHONE
#import "ATFeedbackController.h"
#elif TARGET_OS_MAC
#import "ATFeedbackWindowController.h"
#endif

@implementation ATConnect
@synthesize apiKey, showTagline, shouldTakeScreenshot, showEmailField, initialName, initialEmailAddress, feedbackControllerType, customPlaceholderText;

+ (ATConnect *)sharedConnection {
	static ATConnect *sharedConnection = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConnection = [[ATConnect alloc] init];
	});
	return sharedConnection;
}

- (id)init {
	if ((self = [super init])) {
		self.showEmailField = YES;
		self.showTagline = YES;
		self.shouldTakeScreenshot = NO;
		additionalFeedbackData = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
#if TARGET_OS_IPHONE
	if (feedbackController) {
		[feedbackController release];
		feedbackController = nil;
	}
#elif IF_TARGET_OS_MAC
	if (feedbackWindowController) {
		[feedbackWindowController release];
		feedbackWindowController = nil;
	}
#endif
	[additionalFeedbackData release], additionalFeedbackData = nil;
	[customPlaceholderText release], customPlaceholderText = nil;
	[apiKey release], apiKey = nil;
	[initialName release], initialName = nil;
	[initialEmailAddress release], initialEmailAddress = nil;
	[super dealloc];
}

- (void)setApiKey:(NSString *)anAPIKey {
	if (apiKey != anAPIKey) {
		[apiKey release];
		apiKey = nil;
		apiKey = [anAPIKey retain];
		[[ATBackend sharedBackend] setApiKey:self.apiKey];
	}
}

- (NSDictionary *)additionFeedbackInfo {
	return additionalFeedbackData;
}

- (void)addAdditionalInfoToFeedback:(NSObject *)object withKey:(NSString *)key {
	if ([object isKindOfClass:[NSDate class]]) {
		[additionalFeedbackData setObject:[ATUtilities stringRepresentationOfDate:(NSDate *)object] forKey:key];
	} else {
		[additionalFeedbackData setObject:object forKey:key];
	}
}

- (void)removeAdditionalInfoFromFeedbackWithKey:(NSString *)key {
	[additionalFeedbackData removeObjectForKey:key];
}

#if TARGET_OS_IPHONE
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
	@synchronized(self) {
		if (currentFeedbackController) {
			ATLogInfo(@"Apptentive feedback controller already shown.");
			return;
		}
		UIImage *screenshot = nil;

		if (![[ATBackend sharedBackend] currentFeedback]) {
			ATFeedback *feedback = [[ATFeedback alloc] init];
			if (additionalFeedbackData && [additionalFeedbackData count]) {
				[feedback addExtraDataFromDictionary:additionalFeedbackData];
			}
			if (self.initialName && [self.initialName length] > 0) {
				feedback.name = self.initialName;
			}
			if (self.initialEmailAddress && [self.initialEmailAddress length] > 0) {
				feedback.email = self.initialEmailAddress;
			}
			ATContactStorage *contact = [ATContactStorage sharedContactStorage];
			if (contact.name && [contact.name length] > 0) {
				feedback.name = contact.name;
			}
			if (contact.phone) {
				feedback.phone = contact.phone;
			}
			if (contact.email && [contact.email length] > 0) {
				feedback.email = contact.email;
			}
			[[ATBackend sharedBackend] setCurrentFeedback:feedback];
			[feedback release];
			feedback = nil;
		}
		if ([[ATBackend sharedBackend] currentFeedback]) {
			ATFeedback *currentFeedback = [[ATBackend sharedBackend] currentFeedback];
			if (self.shouldTakeScreenshot && ![currentFeedback hasScreenshot] && self.feedbackControllerType != ATFeedbackControllerSimple) {
				screenshot = [ATUtilities imageByTakingScreenshot];
				// Get the rotation of the view hierarchy and rotate the screenshot as
				// necessary.
				CGFloat rotation = [ATUtilities rotationOfViewHierarchyInRadians:viewController.view];
				screenshot = [ATUtilities imageByRotatingImage:screenshot byRadians:rotation];
				[currentFeedback setScreenshot:screenshot];
			} else if (!self.shouldTakeScreenshot && [currentFeedback hasScreenshot] && (currentFeedback.imageSource == ATFeedbackImageSourceScreenshot)) {
				[currentFeedback setScreenshot:nil];
			}
		}

		ATFeedbackController *vc = [[ATFeedbackController alloc] init];
		[vc setShowEmailAddressField:self.showEmailField];
		if (self.feedbackControllerType == ATFeedbackControllerSimple) {
			vc.deleteCurrentFeedbackOnCancel = YES;
		}
		if (self.customPlaceholderText) {
			[vc setCustomPlaceholderText:self.customPlaceholderText];
		}
		[vc setFeedback:[[ATBackend sharedBackend] currentFeedback]];

		[vc presentFromViewController:viewController animated:YES];
		currentFeedbackController = vc;
	}
}


- (void)dismissFeedbackControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[currentFeedbackController dismissAnimated:animated completion:completion];
}


- (void)feedbackControllerDidDismiss {
	@synchronized(self) {
		[currentFeedbackController release], currentFeedbackController = nil;
	}
}

#elif TARGET_OS_MAC
- (IBAction)showFeedbackWindow:(id)sender {
	if (![[ATBackend sharedBackend] currentFeedback]) {
		ATFeedback *feedback = [[ATFeedback alloc] init];
		if (additionalFeedbackData && [additionalFeedbackData count]) {
			[feedback addExtraDataFromDictionary:additionalFeedbackData];
		}
		if (self.initialName && [self.initialName length] > 0) {
			feedback.name = self.initialName;
		}
		if (self.initialEmailAddress && [self.initialEmailAddress length] > 0) {
			feedback.email = self.initialEmailAddress;
		}
		[[ATBackend sharedBackend] setCurrentFeedback:feedback];
		[feedback release];
		feedback = nil;
	}
	
	if (!feedbackWindowController) {
		feedbackWindowController = [[ATFeedbackWindowController alloc] initWithFeedback:[[ATBackend sharedBackend] currentFeedback]];
	}
	[feedbackWindowController showWindow:self];
}
#endif

+ (NSBundle *)resourceBundle {
#ifdef AT_RESOURCE_BUNDLE
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"ApptentiveResources" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
	return bundle;
#else
	NSBundle *bundle = [NSBundle bundleForClass:[ATConnect class]];
	return bundle;
#endif
}
@end

NSString *ATLocalizedString(NSString *key, NSString *comment) {
	static NSBundle *bundle = nil;
	if (!bundle) {
		bundle = [[ATConnect resourceBundle] retain];
	}
	NSString *result = [bundle localizedStringForKey:key value:key table:nil];
	return result;
}
