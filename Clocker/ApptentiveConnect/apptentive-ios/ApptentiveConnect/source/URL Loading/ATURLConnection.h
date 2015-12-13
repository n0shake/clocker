//
//  ATURLConnection.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATURLConnectionDelegate;

@interface ATURLConnection : NSObject {
	NSURL *targetURL;
	NSObject<ATURLConnectionDelegate> *delegate;
	
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSMutableData *data;
	BOOL executing;
	BOOL finished;
	BOOL failed;
	BOOL cancelled;
	NSTimeInterval timeoutInterval;
	NSURLCredential *credential;
	
	NSMutableDictionary *headers;
	NSString *HTTPMethod;
	NSData *HTTPBody;
	NSInputStream *HTTPBodyStream;
	
	int statusCode;
	BOOL failedAuthentication;
	NSError *connectionError;
	
	float percentComplete;
	
	NSTimeInterval expiresMaxAge;
}
@property (nonatomic, readonly, copy) NSURL *targetURL;
@property (nonatomic, assign) NSObject<ATURLConnectionDelegate> *delegate;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, readonly) BOOL cancelled;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, retain) NSURLCredential *credential;
@property (nonatomic, readonly) int statusCode;
@property (nonatomic, readonly) BOOL failedAuthentication;
@property (nonatomic, copy) NSError *connectionError;
@property (nonatomic, assign) float percentComplete;
@property (nonatomic, readonly) NSTimeInterval expiresMaxAge;

/*! The delegate for this class is a weak reference. */
- (id)initWithURL:(NSURL *)url delegate:(NSObject<ATURLConnectionDelegate> *)aDelegate;
- (id)initWithURL:(NSURL *)url;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)removeHTTPHeaderField:(NSString *)field;
- (void)setHTTPMethod:(NSString *)method;
- (void)setHTTPBody:(NSData *)body;
- (void)setHTTPBodyStream:(NSInputStream *)HTTPBodyStream;

- (void)start;

- (BOOL)isExecuting;
- (BOOL)isCancelled;
- (BOOL)isFinished;
- (NSData *)responseData;

- (NSString *)requestAsString;
- (NSDictionary *)headers;
@end


@protocol ATURLConnectionDelegate <NSObject>
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender;
- (void)connectionFailed:(ATURLConnection *)sender;
- (void)connectionDidProgress:(ATURLConnection *)sender;
@end
