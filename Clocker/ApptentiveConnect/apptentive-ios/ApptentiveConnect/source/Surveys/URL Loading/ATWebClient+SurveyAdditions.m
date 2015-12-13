//
//  ATWebClient+SurveyAdditions.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATWebClient+SurveyAdditions.h"
#import "ATWebClient_Private.h"
#import "ATAPIRequest.h"
#import "ATSurveyResponse.h"
#import "ATURLConnection.h"
#import "PJSONKit.h"

@implementation ATWebClient (SurveyAdditions)
- (ATAPIRequest *)requestForGettingSurveys {
	NSString *urlString = [NSString stringWithFormat:@"%@/surveys?active=1", [self baseURLString]];
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:urlString]];
	conn.timeoutInterval = 20.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeData;
	return [request autorelease];
}


- (ATAPIRequest *)requestForPostingSurveyResponse:(ATSurveyResponse *)surveyResponse {
	NSError *error = nil;
	NSString *postString = [[surveyResponse apiJSON] ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		ATLogError(@"ATWebClient+SurveyAdditions: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"records"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	
	conn.timeoutInterval = 240.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}
@end

void ATWebClient_SurveyAdditions_Bootstrap() {
	NSLog(@"Loading ATWebClient_SurveyAdditions_Bootstrap");
}
