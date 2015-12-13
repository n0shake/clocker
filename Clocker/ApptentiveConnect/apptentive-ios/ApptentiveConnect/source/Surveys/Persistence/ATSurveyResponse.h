//
//  ATSurveyResponse.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATRecord.h"

@class ATSurveyQuestionResponse;

@interface ATSurveyResponse : ATRecord {
	NSMutableArray *questionResponses;
}
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NSUInteger completionSeconds;

- (void)addQuestionResponse:(ATSurveyQuestionResponse *)response;
- (NSDictionary *)apiJSON;
- (NSDictionary *)apiDictionary;
@end


@interface ATSurveyQuestionResponse : NSObject <NSCoding> {
@private
}
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, retain) NSObject<NSCoding> *response;
@end