//
//  ATStaticLibraryBootstrap.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 12/7/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATStaticLibraryBootstrap.h"

#if TARGET_OS_IPHONE
#import "ATToolbar.h"
#import "ATWebClient+SurveyAdditions.h"
#endif
#import "ATWebClient+Metrics.h"
#import "ATURLConnection_Private.h"
#import "ATWebClient_Private.h"

@implementation ATStaticLibraryBootstrap
+ (void)forceStaticLibrarySymbolUsage {
	ATWebClient_Metrics_Bootstrap();
	ATURLConnection_Private_Bootstrap();
	ATWebClient_Private_Bootstrap();
#if TARGET_OS_IPHONE
	ATToolbar_Bootstrap();
	ATWebClient_SurveyAdditions_Bootstrap();
#endif
}
@end
