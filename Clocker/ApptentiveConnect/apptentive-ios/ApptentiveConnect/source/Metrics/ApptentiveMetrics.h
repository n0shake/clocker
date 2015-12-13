//
//  ApptentiveMetrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

@interface ApptentiveMetrics : NSObject {
@private
	BOOL metricsEnabled;
}
+ (ApptentiveMetrics *)sharedMetrics;
@end

