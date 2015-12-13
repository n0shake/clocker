//
//  ATWebClient_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATURLConnection;
@class ATWebClient;

@interface ATWebClient (Private)
- (NSString *)userAgentString;

#pragma mark API URL String
- (NSString *)apiBaseURLString;
- (NSString *)apiURLStringWithPath:(NSString *)path;

#pragma mark Query Parameter Encoding
- (NSString *)stringForParameters:(NSDictionary *)parameters;
- (NSString *)stringForParameter:(id)value;

#pragma mark Internal Methods
- (ATURLConnection *)connectionToGet:(NSURL *)theURL;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL parameters:(NSDictionary *)parameters;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL body:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL withFileData:(NSData *)data ofMimeType:(NSString *)mimeType fileDataKey:(NSString *)fileDataKey  parameters:(NSDictionary *)parameters;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body withFile:(NSString *)path ofMimeType:(NSString *)mimeType;
- (ATURLConnection *)connectionToPut:(NSURL *)theURL JSON:(NSString *)body;
- (void)addAPIHeaders:(ATURLConnection *)conn;
- (void)updateConnection:(ATURLConnection *)conn withOAuthToken:(NSString *)token;
@end

void ATWebClient_Private_Bootstrap();
