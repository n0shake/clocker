//
//  ATCustomButton.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATCustomButton.h"
#import "ATConnect.h"

@implementation ATCustomButton

- (id)initWithButtonStyle:(ATCustomButtonStyle)style {
	ATTrackingButton *button = [ATTrackingButton buttonWithType:UIButtonTypeCustom];
	button.padding = UIEdgeInsetsMake(-10, -20, -10, -15);
	if (style == ATCustomButtonStyleCancel) {
		[button setTitle:ATLocalizedString(@"Cancel", @"Cancel button title") forState:UIControlStateNormal];
		button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
		button.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		button.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		
		[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithRed:130./256. green:130./256. blue:130./256. alpha:1.0] forState:UIControlStateNormal];
		//[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_cancel_bg"] forState:UIControlStateNormal];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_cancel_highlighted_bg"] forState:UIControlStateHighlighted];
		button.layer.cornerRadius = 4.0;
		button.layer.masksToBounds = YES;
		button.layer.borderWidth = 0.5;
		button.layer.borderColor = [UIColor colorWithRed:171./256. green:171./256. blue:171./256. alpha:1.0].CGColor;
		button.layer.shadowColor = [UIColor whiteColor].CGColor;
		button.layer.shadowOffset = CGSizeMake(0.0, 1.0);
		button.layer.shadowRadius = 2.0;
		[button sizeToFit];
	} else if (style == ATCustomButtonStyleSend) {
		[button setTitle:ATLocalizedString(@"Send", @"Send button title") forState:UIControlStateNormal];
		button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
		button.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setTitleShadowColor:[UIColor colorWithRed:63./256. green:63./256. blue:63./256. alpha:1.0] forState:UIControlStateNormal];	
		[button setTitleColor:[UIColor colorWithRed: 0.79 green: 0.86 blue: 0.99 alpha: 1] forState:UIControlStateDisabled];		
		[button setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateDisabled];		
		
		[button setBackgroundImage:[ATBackend imageNamed:@"at_send_bg"] forState:UIControlStateNormal];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_send_highlighted_bg"] forState:UIControlStateHighlighted];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_send_disabled_bg"] forState:UIControlStateDisabled];
		button.layer.cornerRadius = 4.0;
		button.layer.masksToBounds = YES;
		button.layer.shadowColor = [UIColor whiteColor].CGColor;
		button.layer.shadowOffset = CGSizeMake(0.0, 1.0);
		button.layer.shadowRadius = 2.0;
		[button sizeToFit];
		
	}
	
	self = [super initWithCustomView:button];
	if (self) {
		
	}
	return self;
}

- (void)setAction:(SEL)action forTarget:(id)target {
	if ([[self customView] isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)[self customView];
		[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
		self.target = target;
		self.action = action;
	}
	self.target = target;
	self.action = action;
}
@end


@implementation ATTrackingButton
@synthesize padding;

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	CGRect padded = UIEdgeInsetsInsetRect(self.bounds, padding);
	return CGRectContainsPoint(padded, point);
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGRect padded = UIEdgeInsetsInsetRect(self.bounds, padding);
	return CGRectContainsPoint(padded, [touch locationInView:self]);
}

- (void)setupButtonShadow {
	if (shadowView == nil) {
		UIImage *shadowImage = [[ATBackend imageNamed:@"at_button_shadow_overlay"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
		shadowView = [[UIImageView alloc] initWithImage:shadowImage];
		//shadowView.backgroundColor = [UIColor redColor];
		[self addSubview:shadowView];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize s = [super sizeThatFits:size];
	
	CGSize textSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font];
	s.height = size.height < 30  && CGSizeEqualToSize(CGSizeZero, size) == NO ? 23 : 30;
	s.width = textSize.width + 20.0;
	
	return s;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setupButtonShadow];
	shadowView.frame = self.bounds;
	[self bringSubviewToFront:shadowView];
}

- (void)dealloc {
	if (shadowView) {
		[shadowView removeFromSuperview];
		[shadowView release], shadowView = nil;
	}
	[super dealloc];
}
@end
