//
//  ApptentiveSurveysTests.m
//  ApptentiveSurveysTests
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveSurveysTests.h"
#import "ATSurvey.h"
#import "ATSurveyParser.h"
#import "ATSurveyQuestion.h"

@implementation ApptentiveSurveysTests

- (void)setUp
{
	[super setUp];
	
	// Set-up code here.
}

- (void)tearDown
{
	// Tear-down code here.
	
	[super tearDown];
}

- (void)testSurveyParsing {
	NSString *surveyString = @"{\"surveys\":[{\"id\":\"4eb4877cd4d8f8000100002a\",\"questions\":[{\"id\":\"4eb4877cd4d8f8000100002b\",\"answer_choices\":[{\"id\":\"4eb4877cd4d8f8000100002c\",\"value\":\"BMW 335i\"},{\"id\":\"4eb4877cd4d8f8000100002d\",\"value\":\"BMW 335i\"},{\"id\":\"4eb4877cd4d8f8000100002e\",\"value\":\"Bugatti Veyron\"},{\"id\":\"4eb4877cd4d8f8000100002f\",\"value\":\"Tesla Model S\"},{\"id\":\"4eb4877cd4d8f80001000030\",\"value\":\"Dodge Charger\"},{\"id\":\"4eb4877cd4d8f80001000031\",\"value\":\"Other\"}],\"value\":\"Which car would you rather drive?\",\"type\":\"multichoice\"},{\"id\":\"4eb4877cd4d8f80001000032\",\"value\":\"If Other, Please Elaborate:\",\"type\":\"singleline\"},{\"id\":\"4eb4877cd4d8f80001000033\",\"value\":\"How does a really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really long question appear?\",\"type\":\"singleline\"}],\"responses\":[{\"question\":\"Which car would you rather drive?\",\"type\":\"multichoice\",\"responses\":{}},{\"question\":\"If Other, Please Elaborate:\",\"type\":\"singleline\",\"responses\":[]},{\"question\":\"How does a really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really long question appear?\",\"type\":\"singleline\",\"responses\":[]}],\"name\":\"Happy Fun Test Survey\",\"description\":\"This is a fun test survey with a description like this.\",\"active\":true}]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	STAssertNotNil(surveyData, @"Survey data shouldn't be nil");
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	
	STAssertTrue([surveys count] == 1, @"Should only be 1 survey");
	
	ATSurvey *survey = [surveys objectAtIndex:0];
	STAssertTrue([survey.identifier isEqualToString:@"4eb4877cd4d8f8000100002a"], @"id mismatch");
	STAssertTrue([survey.name isEqualToString:@"Happy Fun Test Survey"], @"name mismatch");
	STAssertTrue([survey.surveyDescription isEqualToString:@"This is a fun test survey with a description like this."], @"description mismatch");
	STAssertTrue(survey.isActive, @"Survey should be active");
	STAssertTrue([[survey questions] count] == 3 , @"Should be 3 questions");
	STAssertTrue([survey surveyHasNoTags], @"Survey shouldn't have any tags.");
	
	[survey addTag:@"video"];
	[survey addTag:@"played"];
	NSSet *goodSet = [NSSet setWithObjects:@"video", @"played", nil];
	NSSet *badSet = [NSSet setWithObjects:@"video", @"paused", nil];
	STAssertTrue([survey surveyHasTags:goodSet], @"Survey should have some tags.");
	STAssertFalse([survey surveyHasTags:badSet], @"Survey should not have these tags.");
	
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
	STAssertTrue([question.answerChoices count] == 6, @"First question should have 6 answers");
	
	[parser release], parser = nil;
}

- (void)testEmptySurvey {
	NSString *surveyString = @"{\"surveys\":[]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	STAssertNotNil(surveyData, @"Survey data shouldn't be nil");

	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	STAssertNotNil(surveys, @"shouldn't be nil");
	STAssertTrue([surveys count] == 0, @"Should be zero surveys");
}
@end
