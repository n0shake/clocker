//
//  ATHUDView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	ATHUDCheckmark
} ATHUDMarkType;

@interface ATHUDView : UIWindow {
@private
	UIWindow *parentWindow;
	UIImageView *icon;
}
@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, assign) ATHUDMarkType markType;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat fadeOutDuration;

- (id)initWithWindow:(UIWindow *)window;
- (void)show;
@end
