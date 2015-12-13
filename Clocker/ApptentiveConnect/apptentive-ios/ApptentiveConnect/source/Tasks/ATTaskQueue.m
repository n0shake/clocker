//
//  ATTaskQueue.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATTaskQueue.h"
#import "ATLog.h"
#import "ATBackend.h"
#import "ATTask.h"

#define kATTaskQueueCodingVersion 1
// Retry period in seconds.
#define kATTaskQueueRetryPeriod 180.0

#define kMaxFailureCount 30

static ATTaskQueue *sharedTaskQueue = nil;

@interface ATTaskQueue (Private)
- (void)setup;
- (void)teardown;
- (void)archive;
- (void)unsetActiveTask;
@end

@implementation ATTaskQueue
+ (NSString *)taskQueuePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"tasks.objects"];
}

+ (BOOL)serializedQueueExists {
	NSFileManager *fm = [NSFileManager defaultManager];
	return [fm fileExistsAtPath:[ATTaskQueue taskQueuePath]];
}


+ (ATTaskQueue *)sharedTaskQueue {
	@synchronized(self) {
		if (sharedTaskQueue == nil) {
			if ([ATTaskQueue serializedQueueExists]) {
				@try {
					sharedTaskQueue = [[NSKeyedUnarchiver unarchiveObjectWithFile:[ATTaskQueue taskQueuePath]] retain];
				} @catch (NSException *exception) {
					ATLogError(@"Unable to unarchive tasks at: %@, exception: %@", [ATTaskQueue taskQueuePath], exception);
					sharedTaskQueue = [[ATTaskQueue alloc] init];
				}
			}
			if (!sharedTaskQueue) {
				sharedTaskQueue = [[ATTaskQueue alloc] init];
			}
		}
	}
	return sharedTaskQueue;
}

+ (void)releaseSharedTaskQueue {
	@synchronized(self) {
		if (sharedTaskQueue != nil) {
			[sharedTaskQueue archive];
			[sharedTaskQueue release];
			sharedTaskQueue = nil;
		}
	}
}

- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATTaskQueueCodingVersion) {
			tasks = [[coder decodeObjectForKey:@"tasks"] retain];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATTaskQueueCodingVersion forKey:@"version"];
	@synchronized(self) {
		NSMutableArray *archivableTasks = [[NSMutableArray alloc] init];
		for (ATTask *task in tasks) {
			if ([task shouldArchive]) {
				[archivableTasks addObject:task];
			}
		}
		[coder encodeObject:archivableTasks forKey:@"tasks"];
		[archivableTasks release], archivableTasks = nil;
	}
}

- (void)dealloc {
	[self teardown];
	[super dealloc];
}


- (void)addTask:(ATTask *)task {
	@synchronized(self) {
		[tasks addObject:task];
		[self archive];
	}
	[self start];
}

- (NSUInteger)count {
	NSUInteger count = 0;
	@synchronized(self) {
		count = [tasks count];
	}
	return count;
}

- (ATTask *)taskAtIndex:(NSUInteger)index {
	@synchronized(self) {
		return [tasks objectAtIndex:index];
	}
}

- (NSUInteger)countOfTasksWithTaskNamesInSet:(NSSet *)taskNames {
	NSUInteger count = 0;
	@synchronized(self) {
		for (ATTask *task in tasks) {
			if ([taskNames containsObject:[task taskName]]) {
				count++;
			}
		}
	}
	return count;
}

- (ATTask *)taskAtIndex:(NSUInteger)index withTaskNameInSet:(NSSet *)taskNames {
	NSMutableArray *accum = [NSMutableArray array];
	@synchronized(self) {
		for (ATTask *task in tasks) {
			if ([taskNames containsObject:[task taskName]]) {
				[accum addObject:task];
			}
		}
	}
	if (index < [accum count]) {
		return [accum objectAtIndex:index];
	}
	return nil;
}

- (void)start {
	if ([[NSThread currentThread] isMainThread]) {
		[self performSelectorInBackground:@selector(start) withObject:nil];
		return;
	}
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@synchronized(self) {
		if (activeTask) {
			[pool release], pool = nil;
			return;
		}
		
		if ([tasks count]) {
			for (ATTask *task in tasks) {
				if ([task canStart]) {
					activeTask = task;
					[activeTask addObserver:self forKeyPath:@"finished" options:NSKeyValueObservingOptionNew context:NULL];
					[activeTask addObserver:self forKeyPath:@"failed" options:NSKeyValueObservingOptionNew context:NULL];
					[activeTask start];
					break;
				}
			}
		}
	}
	[pool release], pool = nil;
}

- (void)stop {
	@synchronized(self) {
		[activeTask stop];
		[self unsetActiveTask];
	}
}

- (NSString *)queueDescription {
	NSMutableString *result = [[NSMutableString alloc] init];
	@synchronized(self) {
#if		TARGET_OS_IPHONE
		[result appendString:[NSString stringWithFormat:@"<ATTaskQueue: %d task(s) [", [tasks count]]];
#elif	TARGET_OS_MAC
		[result appendString:[NSString stringWithFormat:@"<ATTaskQueue: %ld task(s) [", (unsigned long)[tasks count]]];
#endif
		NSMutableArray *parts = [[NSMutableArray alloc] init];
		for (ATTask *task in tasks) {
			[parts addObject:[task taskDescription]];
		}
		if ([parts count]) {
			[result appendString:@"\n"];
			[result appendString:[parts componentsJoinedByString:@",\n"]];
			[result appendString:@"\n"];
		}
		[parts release], parts = nil;
		[result appendString:@"]>"];
	}
	return [result autorelease];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	@synchronized(self) {
		if (object != activeTask) return;
		ATTask *task = (ATTask *)object;
		if ([keyPath isEqualToString:@"finished"] && [task finished]) {
			[self unsetActiveTask];
			[task cleanup];
			[tasks removeObject:object];
			[self archive];
			[self start];
		} else if ([keyPath isEqualToString:@"failed"] && [task failed]) {
			if (task.isFailureOkay) {
				task.failureCount = task.failureCount + 1;
				[self unsetActiveTask];
				[tasks removeObject:task];
				[self start];
			} else {
				[self stop];
				task.failureCount = task.failureCount + 1;
				if (task.failureCount > kMaxFailureCount) {
					ATLogError(@"Task %@ failed too many times, removing from queue.", task);
					[self unsetActiveTask];
					[task cleanup];
					[tasks removeObject:task];
					[self start];
				} else {
					// Put task on back of queue.
					[task retain];
					[tasks removeObject:task];
					[tasks addObject:task];
					[task release];
					[self archive];
					
					[self performSelector:@selector(start) withObject:nil afterDelay:kATTaskQueueRetryPeriod];
				}
			}
		}
	}
}
@end

@implementation ATTaskQueue (Private)
- (void)setup {
	@synchronized(self) {
		tasks = [[NSMutableArray alloc] init];
	}
}

- (void)teardown {
	@synchronized(self) {
		[self stop];
		[tasks release], tasks = nil;
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (void)unsetActiveTask {
	@synchronized(self) {
		if (activeTask) {
			[activeTask removeObserver:self forKeyPath:@"finished"];
			[activeTask removeObserver:self forKeyPath:@"failed"];
			activeTask = nil;
		}
	}
}

- (void)archive {
	@synchronized(self) {
		if (![NSKeyedArchiver archiveRootObject:sharedTaskQueue toFile:[ATTaskQueue taskQueuePath]]) {
			ATLogError(@"Unable to archive task queue to: %@", [ATTaskQueue taskQueuePath]);
		}
	}
}
@end
