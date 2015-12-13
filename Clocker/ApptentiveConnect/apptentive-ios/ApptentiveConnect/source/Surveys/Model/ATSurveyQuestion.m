//
//  ATSurveyQuestion.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyQuestion.h"

#define kATSurveyQuestionStorageVersion 1
#define kATSurveyQuestionAnswerStorageVersion 1

@implementation ATSurveyQuestion
@synthesize type;
@synthesize responseRequired;
@synthesize identifier;
@synthesize questionText;
@synthesize instructionsText;
@synthesize value;
@synthesize answerChoices;
@synthesize answerText;
@synthesize selectedAnswerChoices;
@synthesize minSelectionCount;
@synthesize maxSelectionCount;

- (id)init {
	if ((self = [super init])) {
		answerChoices = [[NSMutableArray alloc] init];
		selectedAnswerChoices = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		answerChoices = [[NSMutableArray alloc] init];
		selectedAnswerChoices = [[NSMutableArray alloc] init];
		if (version == kATSurveyQuestionStorageVersion) {
			self.type = [coder decodeIntForKey:@"type"];
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.responseRequired = [coder decodeBoolForKey:@"responseRequired"];
			self.questionText = [coder decodeObjectForKey:@"questionText"];
			self.instructionsText = [coder decodeObjectForKey:@"instructionsText"];
			self.value = [coder decodeObjectForKey:@"value"];
			
			NSArray *decodedAnswerChoices = [coder decodeObjectForKey:@"answerChoices"];
			if (decodedAnswerChoices) {
				[answerChoices addObjectsFromArray:decodedAnswerChoices];
			}
			
			self.answerText = [coder decodeObjectForKey:@"answerText"];
			self.minSelectionCount = [(NSNumber *)[coder decodeObjectForKey:@"minSelectionCount"] unsignedIntegerValue];
			self.maxSelectionCount = [(NSNumber *)[coder decodeObjectForKey:@"maxSelectionCount"] unsignedIntegerValue];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionStorageVersion forKey:@"version"];
	[coder encodeInt:type forKey:@"type"];
	[coder encodeObject:identifier forKey:@"identifier"];
	[coder encodeBool:responseRequired forKey:@"responseRequired"];
	[coder encodeObject:questionText forKey:@"questionText"];
	[coder encodeObject:instructionsText forKey:@"instructionsText"];
	[coder encodeObject:value forKey:@"value"];
	[coder encodeObject:answerChoices forKey:@"answerChoices"];
	[coder encodeObject:answerText forKey:@"answerText"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:minSelectionCount] forKey:@"minSelectionCount"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:maxSelectionCount] forKey:@"maxSelectionCount"];
}

- (void)dealloc {
	[identifier release], identifier = nil;
	[questionText release], questionText = nil;
	[instructionsText release], instructionsText = nil;
	[value release], value = nil;
	[answerChoices release], answerChoices = nil;
	[answerText release], answerText = nil;
	[selectedAnswerChoices release], selectedAnswerChoices = nil;
	[super dealloc];
}

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	[self.answerChoices addObject:answer];
}

- (void)addSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	if (self.type == ATSurveyQuestionTypeMultipleChoice) {
		[self.selectedAnswerChoices removeAllObjects];
	}
	if (![self.selectedAnswerChoices containsObject:answer]) {
		[self.selectedAnswerChoices addObject:answer];
	}
}

- (void)removeSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	[self.selectedAnswerChoices removeObject:answer];
}

- (ATSurveyQuestionValidationErrorType)validateAnswer {
	ATSurveyQuestionValidationErrorType error = ATSurveyQuestionValidationErrorNone;
	
	if (self.type == ATSurveyQuestionTypeSingeLine) {
		if (self.responseIsRequired && (self.answerText == nil || [self.answerText length] == 0)) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleChoice) {
		if (self.responseIsRequired && [self.selectedAnswerChoices count] == 0) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleSelect) {
		if (self.responseIsRequired) {
			if (minSelectionCount != 0 && [self.selectedAnswerChoices count] < minSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooFewAnswers;
			} else if (maxSelectionCount != 0 && [self.selectedAnswerChoices count] > maxSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooManyAnswers;
			}
		}
	}
	return error;
}

- (void)reset {
	[selectedAnswerChoices removeAllObjects];
	self.answerText = nil;
}
@end

@implementation ATSurveyQuestionAnswer
@synthesize identifier;
@synthesize value;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATSurveyQuestionAnswerStorageVersion) {
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.value = [coder decodeObjectForKey:@"value"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionAnswerStorageVersion forKey:@"version"];
	[coder encodeObject:identifier forKey:@"identifier"];
	[coder encodeObject:value forKey:@"value"];
}

- (void)dealloc {
	[identifier release], identifier = nil;
	[value release], value = nil;
	[super dealloc];
}
@end
