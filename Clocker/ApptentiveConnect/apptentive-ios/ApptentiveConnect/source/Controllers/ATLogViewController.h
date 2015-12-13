//
//  ATLogViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/6/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATLogViewController : UIViewController <UITextViewDelegate>
@property (nonatomic, retain) UITextView *textView;

- (IBAction)done:(id)sender;
- (IBAction)reloadLogs:(id)sender;
@end
