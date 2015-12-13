//
//  ATPlaceholderTextView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 8/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ATPlaceholderTextView : NSTextView {
@private
	NSString *placeholder;
}
@property (nonatomic, retain) NSString *placeholder;
- (BOOL)isDefault;
@end
