//
//  ATRecordTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"
#import "ATTask.h"
#import "ATAPIRequest.h"

@class ATRecord;

@interface ATRecordTask : ATTask<ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	ATRecord *record;
}
@property (nonatomic, retain) ATRecord *record;

@end
