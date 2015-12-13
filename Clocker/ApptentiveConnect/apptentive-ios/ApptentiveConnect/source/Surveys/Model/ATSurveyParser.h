//
//  ATSurveyParser.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtSurvey.h"

@interface ATSurveyParser : NSObject {
@private
	NSError *parserError;
}
- (ATSurvey *)parseSurvey:(NSData *)jsonSurvey;
- (NSArray *)parseMultipleSurveys:(NSData *)jsonSurveys;
- (NSError *)parserError;
@end
