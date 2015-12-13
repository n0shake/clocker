//
//  ATURLConnection_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATURLConnection.h"

@interface ATURLConnection (Private)
/*! It's important nobody but ATURLConnection and ATConnectionChannel call this
    selector. */
- (void)cancel;
@end

void ATURLConnection_Private_Bootstrap();
