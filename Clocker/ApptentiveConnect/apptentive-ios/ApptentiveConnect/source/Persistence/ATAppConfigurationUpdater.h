//
//  ATAppConfigurationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATAPIRequest.h"

NSString *const ATConfigurationPreferencesChangedNotification;
NSString *const ATAppConfigurationLastUpdatePreferenceKey;
NSString *const ATAppConfigurationExpirationPreferenceKey;
NSString *const ATAppConfigurationMetricsEnabledPreferenceKey;

@protocol ATAppConfigurationUpdaterDelegate <NSObject>
- (void)configurationUpdaterDidFinish:(BOOL)success;
@end

@interface ATAppConfigurationUpdater : NSObject <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	NSObject<ATAppConfigurationUpdaterDelegate> *delegate;
}
+ (BOOL)shouldCheckForUpdate;
- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end
