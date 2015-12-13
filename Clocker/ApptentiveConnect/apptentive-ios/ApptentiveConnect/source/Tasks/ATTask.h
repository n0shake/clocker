//
//  ATTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATTask : NSObject <NSCoding> {
@private
	BOOL inProgress;
	BOOL finished;
	BOOL failed;
	NSUInteger failureCount;
	NSString *lastErrorTitle;
	NSString *lastErrorMessage;
	BOOL failureOkay;
}
@property (nonatomic, assign) BOOL inProgress;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) NSUInteger failureCount;

@property (nonatomic, copy) NSString *lastErrorTitle;
@property (nonatomic, copy) NSString *lastErrorMessage;
/*! Should we stop the task queue if this task fails, or just throw it away? Defaults to stopping task queue (failureOkay == NO). */
@property (nonatomic, assign, getter=isFailureOkay) BOOL failureOkay;


- (BOOL)canStart;
- (BOOL)shouldArchive;
- (void)start;
- (void)stop;
/*! Called before we delete this task. */
- (void)cleanup;
- (float)percentComplete;
- (NSString *)taskName;

- (NSString *)taskDescription;
@end
