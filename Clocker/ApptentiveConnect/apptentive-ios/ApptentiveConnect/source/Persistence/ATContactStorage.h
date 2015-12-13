//
//  ATContactStorage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATContactStorage : NSObject <NSCoding> {
@private
	NSString *name;
	NSString *email;
	NSString *phone;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *phone;
+ (ATContactStorage *)sharedContactStorage;
+ (void)releaseSharedContactStorage;
- (void)save;
@end
