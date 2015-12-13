//
//  ATFeedbackWindowController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/1/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ATFeedback.h"
#import "ATImageView.h"
#import "ATAPIRequest.h"
#import "ATPlaceholderTextView.h"

@interface ATFeedbackWindowController : NSWindowController <NSWindowDelegate, NSTextViewDelegate, NSComboBoxDelegate, ATAPIRequestDelegate> {
    IBOutlet ATPlaceholderTextView *feedbackTextView;
    IBOutlet ATImageView *screenshotView;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSComboBox *nameBox;
    IBOutlet NSComboBox *emailBox;
    IBOutlet NSComboBox *phoneNumberBox;
    IBOutlet NSButton *sendButton;
	IBOutlet NSButton *cancelButton;
    IBOutlet NSImageView *logoImageView;
@private
    ATAPIRequest *feedbackRequest;
	ATFeedback *feedback;
}
@property (nonatomic, retain) ATFeedback *feedback;
- (id)initWithFeedback:(ATFeedback *)newFeedback;
- (IBAction)browseForScreenshotPressed:(id)sender;
- (IBAction)cancelPressed:(id)sender;
- (IBAction)sendFeedbackPressed:(id)sender;
- (IBAction)openApptentivePressed:(id)sender;
@end
