//
//  ATAppRatingFlow_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATAppRatingClearCountsOnUpgradePreferenceKey;
NSString *const ATAppRatingEnabledPreferenceKey;

NSString *const ATAppRatingUsesBeforePromptPreferenceKey;
NSString *const ATAppRatingDaysBeforePromptPreferenceKey;
NSString *const ATAppRatingDaysBetweenPromptsPreferenceKey;
NSString *const ATAppRatingSignificantEventsBeforePromptPreferenceKey;
NSString *const ATAppRatingPromptLogicPreferenceKey;

NSString *const ATAppRatingSettingsAreFromServerPreferenceKey;

NSString *const ATAppRatingReviewURLPreferenceKey;



NSString *const ATAppRatingFlowLastUsedVersionKey;
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey;
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey;
NSString *const ATAppRatingFlowUserDislikesThisVersionKey;
NSString *const ATAppRatingFlowPromptCountThisVersionKey;
NSString *const ATAppRatingFlowLastPromptDateKey;
NSString *const ATAppRatingFlowRatedAppKey;

NSString *const ATAppRatingFlowUseCountKey;
NSString *const ATAppRatingFlowSignificantEventsCountKey;

@interface ATAppRatingFlowPredicateInfo : NSObject {
@private
	NSDate *firstUse;
	NSUInteger significantEvents;
	NSUInteger appUses;
	
	NSUInteger daysBeforePrompt;
	NSUInteger significantEventsBeforePrompt;
	NSUInteger usesBeforePrompt;
}
@property (nonatomic, retain) NSDate *firstUse;
@property (nonatomic, assign) NSUInteger significantEvents;
@property (nonatomic, assign) NSUInteger appUses;

@property (nonatomic, assign) NSUInteger daysBeforePrompt;
@property (nonatomic, assign) NSUInteger significantEventsBeforePrompt;
@property (nonatomic, assign) NSUInteger usesBeforePrompt;
- (double)now;
- (double)nextPromptDate;
- (NSString *)debugDescription;
@end

@interface ATAppRatingFlow_Private : NSObject
+ (void)registerDefaults;

/*! Can pass in nil for info to just check for a well formed predicate prompt logic object. */
+ (NSString *)predicateStringForPromptLogic:(NSObject *)promptObject withPredicateInfo:(ATAppRatingFlowPredicateInfo *)info hasError:(BOOL *)hasError;

/*! Can pass in nil for info to just check for a well formed predicate prompt logic object. */
+ (NSPredicate *)predicateForPromptLogic:(NSObject *)promptObject withPredicateInfo:(ATAppRatingFlowPredicateInfo *)info;
+ (BOOL)evaluatePredicate:(NSPredicate *)ratingsPredicate withPredicateInfo:(ATAppRatingFlowPredicateInfo *)info;
@end

