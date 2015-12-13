//
//  PSURLManager.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATURLConnection;

@interface ATConnectionManager : NSObject {
	NSMutableDictionary *channels;
}
+ (ATConnectionManager *)sharedSingleton;
- (void)start;
- (void)stop;
- (void)addConnection:(ATURLConnection *)connection toChannel:(NSString *)channelName;
- (void)cancelAllConnectionsInChannel:(NSString *)channelName;
- (void)cancelConnection:(ATURLConnection *)connection inChannel:(NSString *)channelName;
- (void)setMaximumActiveConnections:(NSInteger)maximumConnections forChannel:(NSString *)channelName;
@end
