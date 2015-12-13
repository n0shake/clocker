//
//  ATShadowView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import "ATShadowView.h"

@implementation ATShadowView
@synthesize centerAt, spotlightSize;

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.centerAt = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self setOpaque:NO];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self setOpaque:NO];
	}
	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return size;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)dirtyRect {
	CGRect imageBounds = [self bounds];
	CGRect bounds = [self bounds];
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat alignStroke;
	CGFloat resolution;
	CGMutablePathRef path;
	CGRect drawRect;
	CGGradientRef gradient;
	NSMutableArray *colors;
	UIColor *color;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGAffineTransform transform;
	CGRect pathBounds;
	CGFloat locations[2];
	resolution = 0.5f * (bounds.size.width / imageBounds.size.width + bounds.size.height / imageBounds.size.height);
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, bounds.origin.x, bounds.origin.y);
	CGContextScaleCTM(context, (bounds.size.width / imageBounds.size.width), (bounds.size.height / imageBounds.size.height));
	
	// Layer 1
	
	alignStroke = 0.0f;
	path = CGPathCreateMutable();
	drawRect = CGRectMake(0.0f, 0.0f, imageBounds.size.width, imageBounds.size.height);
	drawRect.origin.x = (roundf(resolution * drawRect.origin.x + alignStroke) - alignStroke) / resolution;
	drawRect.origin.y = (roundf(resolution * drawRect.origin.y + alignStroke) - alignStroke) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	CGPathAddRect(path, NULL, drawRect);
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextEOClip(context);
	pathBounds = CGPathGetPathBoundingBox(path);
	transform = CGAffineTransformMakeTranslation(CGRectGetMidX(pathBounds), CGRectGetMidY(pathBounds));
	CGFloat scale = MAX(0.5f * pathBounds.size.width, 0.5f * pathBounds.size.height);
	transform = CGAffineTransformScale(transform, scale, scale);
	
	
	
	// Get the radius of our rectangle.
	CGFloat width = pathBounds.size.width;
	CGFloat height = pathBounds.size.height;
	CGFloat radius = (sqrt(width*width + height*height))/2.0;
	CGFloat radiusHeightRatio = radius/(MIN(height, width)*0.5);
	
	colors = [NSMutableArray arrayWithCapacity:2];
	color = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
	[colors addObject:(id)[color CGColor]];
	locations[0] = 1.0f;
	color = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5*radiusHeightRatio];
	[colors addObject:(id)[color CGColor]];
	locations[1] = 0.0f;
	gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
	
	CGContextConcatCTM(context, transform);
	CGContextDrawRadialGradient(context, gradient, CGPointZero, radiusHeightRatio, CGPointMake(0.02f, -0.02f), 0.0f, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
	CGContextRestoreGState(context);
	CGGradientRelease(gradient);
	CGPathRelease(path);
	
	CGContextRestoreGState(context);
	CGColorSpaceRelease(space);
}

@end
