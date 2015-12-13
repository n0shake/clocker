//
//  ATRatingPredicateTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATRatingPredicateTests.h"

@implementation ATRatingPredicateTests
- (void)predicateForObject:(NSObject *)promptObject shouldEqualString:(NSString *)result {
	BOOL hasError = NO;
	NSString *predicateString = [ATAppRatingFlow_Private predicateStringForPromptLogic:promptObject withPredicateInfo:nil hasError:&hasError];
	STAssertEqualObjects(predicateString, result, [NSString stringWithFormat:@"%@ doesn't match %@", predicateString, result]);
}

- (NSDictionary *)defaultPromptLogic {
	NSDictionary *innerPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"events", @"uses", nil], @"or", nil];
	NSDictionary *defaultPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", innerPromptLogic, nil], @"and", nil];
	return defaultPromptLogic;
}

- (NSDictionary *)allAndLogic {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"events", @"uses", nil], @"and", nil];
}

- (NSDictionary *)allOrLogic {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"events", @"uses", nil], @"or", nil];
}

- (void)testPredicateStrings {
	[self predicateForObject:[self defaultPromptLogic] shouldEqualString:@"((now >= nextPromptDate) AND ((significantEvents >= significantEventsBeforePrompt) OR (appUses >= usesBeforePrompt)))"];
	[self predicateForObject:[self allAndLogic] shouldEqualString:@"((now >= nextPromptDate) AND (significantEvents >= significantEventsBeforePrompt) AND (appUses >= usesBeforePrompt))"];
	[self predicateForObject:[self allOrLogic] shouldEqualString:@"((now >= nextPromptDate) OR (significantEvents >= significantEventsBeforePrompt) OR (appUses >= usesBeforePrompt))"];
	
	
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 0;
	info.significantEventsBeforePrompt = 5;
	info.usesBeforePrompt = 20;
	
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allAndLogic] withPredicateInfo:info hasError:nil], @"((significantEvents >= significantEventsBeforePrompt) AND (appUses >= usesBeforePrompt))", @"Predicate should not contain disabled parameter.");
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allOrLogic] withPredicateInfo:info hasError:nil], @"((significantEvents >= significantEventsBeforePrompt) OR (appUses >= usesBeforePrompt))", @"Predicate should not contain disabled parameter.");
	
	
	info.daysBeforePrompt = 1;
	info.significantEventsBeforePrompt = 0;
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allAndLogic] withPredicateInfo:info hasError:nil], @"((now >= nextPromptDate) AND (appUses >= usesBeforePrompt))", @"Predicate should not contain disabled parameter.");
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allOrLogic] withPredicateInfo:info hasError:nil], @"((now >= nextPromptDate) OR (appUses >= usesBeforePrompt))", @"Predicate should not contain disabled parameter.");
	
	info.significantEventsBeforePrompt = 5;
	info.usesBeforePrompt = 0;
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allAndLogic] withPredicateInfo:info hasError:nil], @"((now >= nextPromptDate) AND (significantEvents >= significantEventsBeforePrompt))", @"Predicate should not contain disabled parameter.");
	STAssertEqualObjects([ATAppRatingFlow_Private predicateStringForPromptLogic:[self allOrLogic] withPredicateInfo:info hasError:nil], @"((now >= nextPromptDate) OR (significantEvents >= significantEventsBeforePrompt))", @"Predicate should not contain disabled parameter.");
	
	[info release], info = nil;
}

- (void)testDefaultPredicate1 {
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 0;
	info.significantEventsBeforePrompt = 5;
	info.significantEvents = 4;
	info.usesBeforePrompt = 20;
	info.appUses = 3;
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self defaultPromptLogic] withPredicateInfo:info];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	
	info.significantEvents = 6;
	predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self defaultPromptLogic] withPredicateInfo:info];
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	info.appUses = 21;
	predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self defaultPromptLogic] withPredicateInfo:info];
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	info.significantEvents = 4;
	predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self defaultPromptLogic] withPredicateInfo:info];
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	[info release], info = nil;
}

- (void)testAllAndPredicate {
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 30;
	info.significantEventsBeforePrompt = 10;
	info.significantEvents = 4;
	info.usesBeforePrompt = 5;
	info.appUses = 3;
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allAndLogic] withPredicateInfo:info];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	
	info.firstUse = [NSDate dateWithTimeInterval:-1.0*(31*60*60*24) sinceDate:[NSDate date]];
	info.significantEvents = 11;
	info.appUses = 6;
	predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allAndLogic] withPredicateInfo:info];
	
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	
	info.firstUse = [NSDate dateWithTimeInterval:-1.0*(10*60*60*24) sinceDate:[NSDate date]];
	predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allAndLogic] withPredicateInfo:info];

	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	[info release], info = nil;
}

- (void)testOrPredicates {
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 15;
	info.significantEventsBeforePrompt = 0;
	info.significantEvents = 0;
	info.usesBeforePrompt = 10;
	info.appUses = 3;
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allOrLogic] withPredicateInfo:info];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	
	NSPredicate *missingClause = [ATAppRatingFlow_Private predicateForPromptLogic:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"uses", nil], @"or", nil] withPredicateInfo:info];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:missingClause withPredicateInfo:info], @"Predicate should not be true.");
	info.appUses = 11;
	missingClause = [ATAppRatingFlow_Private predicateForPromptLogic:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"uses", nil], @"or", nil] withPredicateInfo:info];
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:missingClause withPredicateInfo:info], @"Predicate should be true.");
	info.appUses = 3;
	missingClause = [ATAppRatingFlow_Private predicateForPromptLogic:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"uses", nil], @"or", nil] withPredicateInfo:info];
	
	NSPredicate *noClauses = [ATAppRatingFlow_Private predicateForPromptLogic:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:nil], @"or", nil] withPredicateInfo:nil];
	STAssertTrue(noClauses == nil, @"noClauses should be nil");
	[info release], info = nil;
}

- (void)testNilInfo {
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allOrLogic] withPredicateInfo:nil];
	STAssertNotNil(predicate, @"Should be able to validate predicate with nil info.");
}
@end
