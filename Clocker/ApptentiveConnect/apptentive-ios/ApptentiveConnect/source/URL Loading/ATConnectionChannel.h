//
//  PSURLChannel.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATURLConnection;

@interface ATConnectionChannel : NSObject {
	NSInteger maximumConnections;
	NSMutableSet *active;
	NSMutableArray *waiting;
}
@property (nonatomic, assign) NSInteger maximumConnections;

- (void)update;
- (void)addConnection:(ATURLConnection *)connection;
- (void)cancelAllConnections;
- (void)cancelConnection:(ATURLConnection *)connection;
@end
