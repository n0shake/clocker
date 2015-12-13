//
//  ATShadowView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATShadowView : UIView {
@private
	CGPoint centerAt;
	CGSize spotlightSize;
}
@property (nonatomic, assign) CGPoint centerAt;
@property (nonatomic, assign) CGSize spotlightSize;
@end
