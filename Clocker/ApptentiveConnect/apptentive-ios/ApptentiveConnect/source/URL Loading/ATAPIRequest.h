//
//  ATAPIRequest.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATURLConnection.h"

NSString *const ATAPIRequestStatusChanged;

@class ATAPIRequest;

typedef enum {
	ATAPIRequestReturnTypeData,
	ATAPIRequestReturnTypeString,
	ATAPIRequestReturnTypeJSON
} ATAPIRequestReturnType;

@protocol ATAPIRequestDelegate <NSObject>
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result;
- (void)at_APIRequestDidFail:(ATAPIRequest *)request;
@optional
- (void)at_APIRequestDidProgress:(ATAPIRequest *)request;
@end

/*! API request for the apptentive.com service. Encapsulates the connection
 connection state, completion percentage, etc. */
@interface ATAPIRequest : NSObject <ATURLConnectionDelegate> {
@private
	ATURLConnection *connection;
	NSString *channelName;
	BOOL cancelled;
	float percentageComplete;
	
	ATAPIRequestReturnType returnType;
	BOOL failed;
	NSString *errorTitle;
	NSString *errorMessage;
	NSString *errorResponse;
	NSTimeInterval timeoutInterval;
	NSObject<ATAPIRequestDelegate> *delegate;
	
	NSTimeInterval expiresMaxAge;
}
@property (nonatomic, assign) ATAPIRequestReturnType returnType;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, copy) NSString *errorTitle;
@property (nonatomic, copy) NSString *errorMessage;
@property (nonatomic, copy) NSString *errorResponse;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSObject<ATAPIRequestDelegate> *delegate;

- (id)initWithConnection:(ATURLConnection *)connection channelName:(NSString *)channelName;
- (void)start;
- (void)cancel;
- (void)showAlert;
- (float)percentageComplete;
- (NSTimeInterval)expiresMaxAge;
@end

