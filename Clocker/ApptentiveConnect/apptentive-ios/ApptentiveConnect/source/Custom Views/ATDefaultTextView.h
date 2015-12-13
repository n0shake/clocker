//
//  ATDefaultTextView.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ATDefaultTextView : UITextView {
@private
	UILabel *placeholderLabel;
}
@property (nonatomic, copy) NSString *placeholder;
- (BOOL)isDefault;
@end
