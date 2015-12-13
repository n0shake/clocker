//
//  ATImageButton.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/2/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATImageButton.h"


@implementation ATImageButton
- (void)mouseDown:(NSEvent *)theEvent {
    if ([self target] && [self action]) {
        [NSApp sendAction:[self action] to:[self target] from:self];
    }
}
@end
