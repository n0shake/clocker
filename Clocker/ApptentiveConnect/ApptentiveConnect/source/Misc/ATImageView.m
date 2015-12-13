//
//  ATImageView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/28/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATImageView.h"


NSString *const ATImageViewContentsChanged = @"ATImageViewContentsChanged";

@implementation ATImageView
 
- (void)setImage:(NSImage *)newImage {
    BOOL wasNew = NO;
    if ([self image] != newImage) {
        wasNew = YES;
    }
    [super setImage:newImage];
    if (wasNew) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ATImageViewContentsChanged object:self];
    }
}
@end

