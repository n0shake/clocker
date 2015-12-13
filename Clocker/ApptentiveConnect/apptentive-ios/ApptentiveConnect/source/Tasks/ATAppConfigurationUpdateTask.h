//
//  ATAppConfigurationUpdateTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ATAppConfigurationUpdater.h"

@interface ATAppConfigurationUpdateTask : ATTask <ATAppConfigurationUpdaterDelegate> {
@private
	ATAppConfigurationUpdater *configurationUpdater;
}

@end
