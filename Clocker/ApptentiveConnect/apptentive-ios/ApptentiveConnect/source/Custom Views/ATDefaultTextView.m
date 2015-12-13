//
//  ATDefaultTextView.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATDefaultTextView.h"

@interface ATDefaultTextView (Private)
- (void)setup;
- (void)setupPlaceholder;
- (void)didEdit:(NSNotification *)notification;
@end

@implementation ATDefaultTextView
@synthesize placeholder;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}

- (void)dealloc {
	self.placeholder = nil;
	[placeholderLabel removeFromSuperview];
	[placeholderLabel release];
	placeholderLabel = nil;
	[super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setupPlaceholder];
}

- (void)setPlaceholder:(NSString *)newPlaceholder {
	if (placeholder != newPlaceholder) {
		[placeholder release];
		placeholder = nil;
		placeholder = [newPlaceholder retain];
		[self setupPlaceholder];
	}
}

- (BOOL)isDefault {
	if (!self.text || [self.text length] == 0) return YES;
	return NO;
}
@end


@implementation ATDefaultTextView (Private)

- (void)setup {
	self.text = @"";
	placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	placeholderLabel.userInteractionEnabled = NO;
	placeholderLabel.backgroundColor = [UIColor clearColor];
	placeholderLabel.opaque = NO;
	placeholderLabel.textColor = [UIColor lightGrayColor];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidBeginEditingNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidEndEditingNotification object:self];
	[self setupPlaceholder];
}

- (void)setupPlaceholder {
	if ([self isDefault]) {
		placeholderLabel.text = self.placeholder;
		placeholderLabel.font = self.font;
		placeholderLabel.textAlignment = self.textAlignment;
		placeholderLabel.numberOfLines = 0;
		placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[placeholderLabel sizeToFit];
		[self addSubview:placeholderLabel];
		CGFloat padding = 8.0;
		CGRect b = placeholderLabel.bounds;
		b.size.width = self.bounds.size.width - padding*2.0;
		placeholderLabel.bounds = b;
		CGRect f = placeholderLabel.frame;
		f.origin = CGPointMake(padding, padding);
		placeholderLabel.frame = f;
		[self sendSubviewToBack:placeholderLabel];
	} else {
		[placeholderLabel removeFromSuperview];
	}
}

- (void)didEdit:(NSNotification *)notification {
	if (notification.object == self) {
		[self setupPlaceholder];
	}
}
@end
