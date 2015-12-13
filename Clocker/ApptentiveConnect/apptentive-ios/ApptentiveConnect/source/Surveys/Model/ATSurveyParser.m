//
//  ATSurveyParser.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyParser.h"
#import "PJSONKit.h"
#import "ATSurveyQuestion.h"

@interface ATSurveyParser ()
- (ATSurveyQuestionAnswer *)answerWithJSONDictionary:(NSDictionary *)jsonDictionary;
- (ATSurveyQuestion *)questionWithJSONDictionary:(NSDictionary *)jsonDictionary;
- (ATSurvey *)surveyWithJSONDictionary:(NSDictionary *)jsonDictionary;
@end

@implementation ATSurveyParser

- (ATSurveyQuestionAnswer *)answerWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATSurveyQuestionAnswer *answer = [[ATSurveyQuestionAnswer alloc] init];
	BOOL failed = NO;
	
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"identifier", @"id", @"value", @"value", nil];
	
	for (NSString *key in keyMapping) {
		NSString *ivarName = [keyMapping objectForKey:key];
		NSObject *value = [jsonDictionary objectForKey:key];
		if (value && [value isKindOfClass:[NSString class]]) {
			[answer setValue:value forKey:ivarName];
		} else {
			failed = YES;
		}
	}
	
	if (failed == YES) {
		[answer release], answer = nil;
	}
	return [answer autorelease];
}

- (ATSurveyQuestion *)questionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATSurveyQuestion *question = [[ATSurveyQuestion alloc] init];
	BOOL failed = YES;
	
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"identifier", @"id", @"questionText", @"value", @"instructionsText", @"instructions", nil];
	
	for (NSString *key in keyMapping) {
		NSString *ivarName = [keyMapping objectForKey:key];
		NSObject *value = [jsonDictionary objectForKey:key];
		if (value && [value isKindOfClass:[NSString class]]) {
			[question setValue:value forKey:ivarName];
		}
	}
	
	do { // once
		NSObject *typeString = [jsonDictionary objectForKey:@"type"];
		if (typeString == nil || ![typeString isKindOfClass:[NSString class]]) {
			break;
		}
		
		if ([(NSString *)typeString isEqualToString:@"multichoice"]) {
			question.type = ATSurveyQuestionTypeMultipleChoice;
		} else if ([(NSString *)typeString isEqualToString:@"multiselect"]) {
			question.type = ATSurveyQuestionTypeMultipleSelect;
		} else if ([(NSString *)typeString isEqualToString:@"singleline"]) {
			question.type = ATSurveyQuestionTypeSingeLine;
		} else {
			break;
		}
		
		if ([jsonDictionary objectForKey:@"required"] != nil) {
			question.responseRequired = [(NSNumber *)[jsonDictionary objectForKey:@"required"] boolValue];
		}
		
		if ([jsonDictionary objectForKey:@"max_selections"] != nil) {
			question.maxSelectionCount = [(NSNumber *)[jsonDictionary objectForKey:@"max_selections"] unsignedIntegerValue];
		}
		if ([jsonDictionary objectForKey:@"min_selections"] != nil) {
			question.minSelectionCount = [(NSNumber *)[jsonDictionary objectForKey:@"min_selections"] unsignedIntegerValue];
		}
		
		if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			NSObject *answerChoices = [jsonDictionary objectForKey:@"answer_choices"];
			if (answerChoices == nil || ![answerChoices isKindOfClass:[NSArray class]]) {
				break;
			}
			
			for (NSObject *answerDict in (NSDictionary *)answerChoices) {
				if (![answerDict isKindOfClass:[NSDictionary class]]) {
					continue;
				}
				ATSurveyQuestionAnswer *answer = [self answerWithJSONDictionary:(NSDictionary *)answerDict];
				if (answer != nil) {
					[question addAnswerChoice:answer];
				}
			}
		}
		
		failed = NO;
	} while (NO);
	
	if (failed == YES) {
		[question release], question = nil;
	}
	
	return [question autorelease];
}

- (ATSurvey *)surveyWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATSurvey *survey = [[ATSurvey alloc] init];
	
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"surveyDescription", @"description", @"identifier", @"id", @"name", @"name", @"successMessage", @"success_message", nil];
	
	for (NSString *key in keyMapping) {
		NSString *ivarName = [keyMapping objectForKey:key];
		NSObject *value = [jsonDictionary objectForKey:key];
		if (value && [value isKindOfClass:[NSString class]]) {
			[survey setValue:value forKey:ivarName];
		}
	}
	
	if ([jsonDictionary objectForKey:@"active"] != nil) {
		survey.active = [(NSNumber *)[jsonDictionary objectForKey:@"active"] boolValue];
	}
	if ([jsonDictionary objectForKey:@"required"] != nil) {
		survey.responseRequired = [(NSNumber *)[jsonDictionary objectForKey:@"required"] boolValue];
	}
	
	if ([jsonDictionary objectForKey:@"multiple_responses"] != nil) {
		survey.multipleResponsesAllowed = [(NSNumber *)[jsonDictionary objectForKey:@"multiple_responses"] boolValue];
	}
	if ([jsonDictionary objectForKey:@"tags"] != nil) {
		for (NSString *tag in [jsonDictionary objectForKey:@"tags"]) {
			[survey addTag:tag];
		}
	}
	
	NSObject *questions = [jsonDictionary objectForKey:@"questions"];
	if ([questions isKindOfClass:[NSArray class]]) {
		for (NSObject *question in (NSArray *)questions) {
			if ([question isKindOfClass:[NSDictionary class]]) {
				ATSurveyQuestion *result = [self questionWithJSONDictionary:(NSDictionary *)question];
				if (result != nil) {
					[survey addQuestion:result];
				}
			}
		}
	}
	
	return [survey autorelease];
}

- (ATSurvey *)parseSurvey:(NSData *)jsonSurvey {
	ATSurvey *survey = nil;
	BOOL success = NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ATJSONDecoder *decoder = [ATJSONDecoder decoder];
	NSError *error = nil;
	id decodedObject = [decoder objectWithData:jsonSurvey error:&error];
	if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
		success = YES;
		NSDictionary *values = (NSDictionary *)decodedObject;
		survey = [self surveyWithJSONDictionary:values];
		[survey retain];
	} else {
		[parserError release], parserError = nil;
		parserError = [error retain];
		success = NO;
	}
	
	[pool release], pool = nil;
	if (!success) {
		survey = nil;
	} else {
		[survey autorelease];
	}
	return survey;
}

- (NSArray *)parseMultipleSurveys:(NSData *)jsonSurveys {
	NSMutableArray *result = [NSMutableArray array];
	BOOL success = NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ATJSONDecoder *decoder = [ATJSONDecoder decoder];
	NSError *error = nil;
	
	id decodedObject = [decoder objectWithData:jsonSurveys error:&error];
	if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary *surveysContainer = (NSDictionary *)decodedObject;
		NSArray *surveys = [surveysContainer objectForKey:@"surveys"];
		if (surveys) {
			success = YES;
			for (NSObject *obj in surveys) {
				if ([obj isKindOfClass:[NSDictionary class]]) {
					NSDictionary *dict = (NSDictionary *)obj;
					ATSurvey *survey = [self surveyWithJSONDictionary:dict];
					if (survey != nil) {
						[result addObject:survey];
					}
				}
			}
		}
	} else {
		[parserError release], parserError = nil;
		parserError = [error retain];
		success = NO;
	}
	
	[pool release], pool = nil;
	
	if (!success) {
		result = nil;
	}
	
	return result;
}

- (NSError *)parserError {
	return parserError;
}

- (void)dealloc {
	[parserError release], parserError = nil;
	[super dealloc];
}
@end
