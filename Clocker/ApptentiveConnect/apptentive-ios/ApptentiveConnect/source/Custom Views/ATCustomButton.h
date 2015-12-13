//
//  ATCustomButton.h
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ATBackend.h"

typedef enum {
	ATCustomButtonStyleCancel,
	ATCustomButtonStyleSend
} ATCustomButtonStyle;

@interface ATTrackingButton : UIButton {
@private
	UIImageView *shadowView;
	UIEdgeInsets padding;
}
@property (nonatomic, assign) UIEdgeInsets padding;
@end

@interface ATCustomButton : UIBarButtonItem
- (id)initWithButtonStyle:(ATCustomButtonStyle)style;
- (void)setAction:(SEL)action forTarget:(id)target;
@end
