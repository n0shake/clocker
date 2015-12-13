//
//  ATCenteringImageScrollView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ATCenteringImageScrollView : UIScrollView {
@private
	UIImageView *imageView;
}
- (id)initWithImage:(UIImage *)image;
- (UIImageView *)imageView;
@end
