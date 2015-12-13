//
//  ATSurvey.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurvey.h"

#define kATSurveyStorageVersion 1

@implementation ATSurvey
@synthesize responseRequired;
@synthesize multipleResponsesAllowed;
@synthesize active;
@synthesize identifier;
@synthesize name;
@synthesize surveyDescription;
@synthesize questions;
@synthesize tags;
@synthesize successMessage;

- (id)init {
	if ((self = [super init])) {
		questions = [[NSMutableArray alloc] init];
		tags = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		questions = [[NSMutableArray alloc] init];
		tags = [[NSMutableArray alloc] init];
		if (version == kATSurveyStorageVersion) {
			self.active = [coder decodeBoolForKey:@"active"];
			self.responseRequired = [coder decodeBoolForKey:@"responseRequired"];
			self.multipleResponsesAllowed = [coder decodeBoolForKey:@"multipleResponsesAllowed"];
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.surveyDescription = [coder decodeObjectForKey:@"surveyDescription"];
			NSArray *decodedQuestions = [coder decodeObjectForKey:@"questions"];
			if (decodedQuestions) {
				[questions addObjectsFromArray:decodedQuestions];
			}
			NSArray *decodedTags = [coder decodeObjectForKey:@"tags"];
			if (decodedTags) {
				[tags addObjectsFromArray:decodedTags];
			}
			self.successMessage = [coder decodeObjectForKey:@"successMessage"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyStorageVersion forKey:@"version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeBool:self.isActive forKey:@"active"];
	[coder encodeBool:self.responseIsRequired forKey:@"responseRequired"];
	[coder encodeBool:self.multipleResponsesAllowed forKey:@"multipleResponsesAllowed"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.surveyDescription forKey:@"surveyDescription"];
	[coder encodeObject:self.questions forKey:@"questions"];
	[coder encodeObject:self.tags forKey:@"tags"];
	[coder encodeObject:self.successMessage forKey:@"successMessage"];
}

- (void)dealloc {
	[questions release], questions = nil;
	[identifier release], identifier = nil;
	[name release], name = nil;
	[surveyDescription release], surveyDescription = nil;
	[successMessage release], successMessage = nil;
	[tags release], tags = nil;
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<ATSurvey: %p {name:%@, identifier:%@}>", self, self.name, self.identifier];
}

- (void)addQuestion:(ATSurveyQuestion *)question {
	[questions addObject:question];
}

- (void)addTag:(NSString *)tag {
	if (tag && [tag length]) {
		[tags addObject:[tag lowercaseString]];
	}
}

- (BOOL)surveyHasNoTags {
	if (self.tags == nil || [self.tags count] == 0) {
		return YES;
	}
	return NO;
}

- (BOOL)surveyHasTags:(NSSet *)tagsToCheck {
	if (tagsToCheck == nil || [tagsToCheck count] == 0) {
		return YES;
	}
	
	// We want to make sure that all of the tags to check are present.
	if (self.tags == nil || [self.tags count] == 0) {
		return NO;
	}
	
	NSSet *tagSet = [NSSet setWithArray:self.tags];
	BOOL isSubset = YES;
	for (NSString *tag in tagsToCheck) {
		// We want to check lower case tags, so don't just use NSSet methods.
		NSString *lowercaseTag = [tag lowercaseString];
		if (![tagSet containsObject:lowercaseTag]) {
			isSubset = NO;
			break;
		}
	}
	
	return isSubset;
}

- (void)reset {
	for (ATSurveyQuestion *question in questions) {
		[question reset];
	}
}
@end
