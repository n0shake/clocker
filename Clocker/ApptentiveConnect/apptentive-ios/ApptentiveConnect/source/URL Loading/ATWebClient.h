//
//  ATWebClient.h
//  apptentive-ios
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATFeedback;
@class ATAPIRequest;

extern NSString *const ATWebClientDefaultChannelName;

/*! Singleton for generating API requests. */
@interface ATWebClient : NSObject {
}
+ (ATWebClient *)sharedClient;
- (NSString *)baseURLString;
- (NSString *)commonChannelName;
- (ATAPIRequest *)requestForPostingFeedback:(ATFeedback *)feedback;
- (ATAPIRequest *)requestForGettingAppConfiguration;
@end
