//
//  ATSurveysBackend.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSurvey;

@interface ATSurveysBackend : NSObject {
@private
	NSMutableArray *availableSurveys;
	ATSurvey *currentSurvey;
}
+ (ATSurveysBackend *)sharedBackend;
- (void)checkForAvailableSurveys;
- (ATSurvey *)currentSurvey;
- (void)resetSurvey;
- (void)presentSurveyControllerWithNoTagsFromViewController:(UIViewController *)viewController;
- (void)presentSurveyControllerWithTags:(NSSet *)tags fromViewController:(UIViewController *)viewController;
- (void)setDidSendSurvey:(ATSurvey *)survey;
- (BOOL)hasSurveyAvailableWithNoTags;
- (BOOL)hasSurveyAvailableWithTags:(NSSet *)tags;
@end


@interface ATSurveysBackend (Private)
- (BOOL)surveyAlreadySubmitted:(ATSurvey *)survey;
- (void)didReceiveNewSurveys:(NSArray *)surveys maxAge:(NSTimeInterval)expiresMaxAge;
@end