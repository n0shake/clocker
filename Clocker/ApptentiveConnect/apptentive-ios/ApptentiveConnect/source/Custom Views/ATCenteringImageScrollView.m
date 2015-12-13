//
//  ATCenteringImageScrollView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATCenteringImageScrollView.h"


@implementation ATCenteringImageScrollView

- (id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		imageView = [[UIImageView alloc] initWithImage:image];
		self.frame = imageView.bounds;
		[self addSubview:imageView];
		self.contentSize = imageView.bounds.size;
	}
	return self;
}

- (void)dealloc {
	[imageView removeFromSuperview];
	[imageView release];
	imageView = nil;
	[super dealloc];
}

- (UIImageView *)imageView {
	return imageView;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// Center the image.
	CGSize boundsSize = self.bounds.size;
	CGRect frameToCenter = imageView.frame;
	if (frameToCenter.size.width < boundsSize.width) {
		frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width)/2.0;
	} else {
		frameToCenter.origin.x = 0.0;
	}
	if (frameToCenter.size.height < boundsSize.height) {
		frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height)/2.0;
	} else {
		frameToCenter.origin.y = 0.0;
	}
	imageView.frame = frameToCenter;
}
@end
