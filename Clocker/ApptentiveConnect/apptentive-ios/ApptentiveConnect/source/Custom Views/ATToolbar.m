//
//  ATToolbar.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATToolbar.h"
#import "ATCustomButton.h"

@implementation ATToolbar
//!! Hack to adjust frame origin of left-most custom view and to force
//!! custom views to resize on orientation changes.
//!! Still has problems if the text is too big to fit and is rotated to portrait twice.
//!! This is a huge hack.
- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSArray *items = [self items];
	CGFloat widthAvailable = self.bounds.size.width;
	
	BOOL viewHasTwoButtons = NO;
	NSUInteger buttonCount = 0;
	for (UIBarButtonItem *item in items) {
		if ([item isKindOfClass:[ATCustomButton class]]) {
			buttonCount++;
		}
	}
	if (buttonCount == 2) {
		viewHasTwoButtons = YES;
	}
	
	NSUInteger customButtonIndex = 0;
	for (UIBarButtonItem *item in items) {
		if (item.customView != nil && item.customView.superview != nil) {
			[item.customView sizeToFit];
			if (viewHasTwoButtons && [item isKindOfClass:[ATCustomButton class]]) {
				CGRect frameInView = [item.customView.superview convertRect:item.customView.frame toView:self];
				if (customButtonIndex == 0) {
					widthAvailable -= CGRectGetMaxX(frameInView);
				} else if (customButtonIndex == 1) {
					CGFloat buttonOriginWidth = (self.bounds.size.width - frameInView.origin.x);
					widthAvailable -= buttonOriginWidth;
				}
				customButtonIndex++;
			}
		}
	}
	
	if ([items count] > 0) {
		UIBarButtonItem *firstItem = [items objectAtIndex:0];
		
		BOOL adjustedFirstItem = NO;
		if (firstItem.customView != nil) {
			CGRect f = firstItem.customView.frame;
			if (f.origin.x == 12.0) {
				f.origin.x = 6.0;
				firstItem.customView.frame = f;
				adjustedFirstItem = YES;
			}
		}
		
		if (adjustedFirstItem) {
			NSUInteger i = 0;
			for (UIBarButtonItem *item in items) {
				// Also don't adjust any custom buttons.
				if (i != 0 && item.customView != nil && ![item isKindOfClass:[ATCustomButton class]]) {
					CGRect customFrame = item.customView.frame;
					customFrame.origin.x += 4.0;
					customFrame.size.width = MIN(widthAvailable, customFrame.size.width);
					item.customView.frame = customFrame;
				}
				i++;
			}
		}
	}
}

- (void)drawRect:(CGRect)rect {
	//
}
@end


void ATToolbar_Bootstrap() {
	NSLog(@"Loading ATToolbar_Bootstrap");
}
