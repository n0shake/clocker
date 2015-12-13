//
//  PSURLManager.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ATConnectionManager.h"
#import "ATConnectionChannel.h"

static ATConnectionManager *sharedSingleton = nil;

#define PLACEHOLDER_CHANNEL_NAME @"ATDefaultChannel"

@interface ATConnectionManager ()
- (ATConnectionChannel *)channelForName:(NSString *)channelName;
@end

@implementation ATConnectionManager
+ (ATConnectionManager *)sharedSingleton {
	@synchronized(self) {
		if (!sharedSingleton) {
			sharedSingleton = [[ATConnectionManager alloc] init];
		}
	}
	return sharedSingleton;
}

- (id)init {
	if ((self = [super init])) {
		channels = [[NSMutableDictionary alloc] init];
		return self;
	}
	return nil;
}

- (void)start {
	for (ATConnectionChannel *channel in [channels allValues]) {
		[channel update];
	}
}

- (void)stop {
	for (ATConnectionChannel *channel in [channels allValues]) {
		[channel cancelAllConnections];
	}
}

- (void)addConnection:(ATURLConnection *)connection toChannel:(NSString *)channelName {
	ATConnectionChannel *channel = [self channelForName:channelName];
	[channel addConnection:connection];
}

- (void)cancelAllConnectionsInChannel:(NSString *)channelName {
	ATConnectionChannel *channel = [self channelForName:channelName];
	[channel cancelAllConnections];
}

- (void)cancelConnection:(ATURLConnection *)connection inChannel:(NSString *)channelName {
	ATConnectionChannel *channel = [self channelForName:channelName];
	[channel cancelConnection:connection];
}

- (void)setMaximumActiveConnections:(NSInteger)maximumConnections forChannel:(NSString *)channelName {
	ATConnectionChannel *channel = [self channelForName:channelName];
	channel.maximumConnections = maximumConnections;
}


- (ATConnectionChannel *)channelForName:(NSString *)channelName {
	if (!channelName) {
		channelName = PLACEHOLDER_CHANNEL_NAME;
	}
	ATConnectionChannel *channel = [channels objectForKey:channelName];
	if (!channel) {
		channel = [[ATConnectionChannel alloc] init];
		[channels setObject:channel forKey:channelName];
		[channel release];
	}
	return channel;
}

- (void)dealloc {
	[self stop];
	[channels removeAllObjects];
	[channels release];
	channels = nil;
	[super dealloc];
}
@end
