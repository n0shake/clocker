//
//  ATSurveyMetrics.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATSurveyDidShowWindowNotification; // survey.launch
NSString *const ATSurveyDidHideWindowNotification; // survey.cancel or survey.submit
NSString *const ATSurveyDidAnswerQuestionNotification; // survey.question_response

NSString *const ATSurveyWindowTypeKey;
NSString *const ATSurveyMetricsEventKey;
NSString *const ATSurveyMetricsSurveyIDKey;
NSString *const ATSurveyMetricsSurveyQuestionIDKey;

typedef enum {
	ATSurveyWindowTypeSurvey,
} ATSurveyWindowType;

typedef enum {
	ATSurveyEventUnknown,
	ATSurveyEventTappedCancel,
	ATSurveyEventTappedSend,
	ATSurveyEventAnsweredQuestion,
} ATSurveyEvent;
