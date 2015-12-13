//
//  ATPlaceholderTextView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 8/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPlaceholderTextView.h"

@implementation ATPlaceholderTextView
@synthesize placeholder;

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
    }
    return self;
}

- (void)dealloc {
	[placeholder release], placeholder = nil;
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	if (placeholder != nil && [self isDefault]) {
		CGRect r = NSRectToCGRect([self frame]);
		r.origin.x += 6;
		CGSize inset = NSSizeToCGSize([self textContainerInset]);
		NSRect textRect = NSRectFromCGRect(CGRectInset(r, inset.width, inset.height));
		NSAttributedString *s = [[NSAttributedString alloc] initWithString:self.placeholder attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]];
		[s drawInRect:textRect];
		[s release], s = nil;
	}
}

- (void)setPlaceholder:(NSString *)newPlaceholder {
	if (placeholder != newPlaceholder) {
		[placeholder release];
		placeholder = nil;
		placeholder = [newPlaceholder retain];
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isDefault {
	if (![self string] || [[self string] length] == 0) return YES;
	return NO;
}

- (BOOL)becomeFirstResponder {
	if (placeholder != nil) {
		[self setNeedsDisplay:YES];
	}
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	if (placeholder != nil) {
		[self setNeedsDisplay:YES];
	}
	return [super resignFirstResponder];
}
@end
