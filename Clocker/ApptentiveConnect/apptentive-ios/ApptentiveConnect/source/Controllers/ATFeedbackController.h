//
//  ATFeedbackController.h
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATSimpleImageViewController.h"

@class ATDefaultTextView;
@class ATFeedback;
@class ATToolbar;

@interface ATFeedbackController : UIViewController <ATSimpleImageViewControllerDelegate, UITextFieldDelegate> {
	UIViewController *presentingViewController;
	
@private
	UIStatusBarStyle startingStatusBarStyle;
	UIImageView *paperclipView;
	UIImageView *paperclipBackgroundView;
	UIView *photoFrameContainerView;
	UIControl *photoControl;
	UIImage *currentImage;
	BOOL showEmailAddressField;
	BOOL deleteCurrentFeedbackOnCancel;
	
	UIPanGestureRecognizer *photoPanRecognizer;
	CGPoint photoDragOffset;
	CGAffineTransform photoFrameTransform;
	
	UIWindow *originalPresentingWindow;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet ATToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *redLineView;
@property (nonatomic, retain) IBOutlet UIView *grayLineView;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UIView *feedbackContainerView;
@property (nonatomic, retain) IBOutlet ATDefaultTextView *feedbackView;
@property (nonatomic, retain) IBOutlet UIControl *logoControl;
@property (nonatomic, retain) IBOutlet UIImageView *logoImageView;
@property (nonatomic, retain) IBOutlet UILabel *taglineLabel;


@property (nonatomic, retain) ATFeedback *feedback;
@property (nonatomic, copy) NSString *customPlaceholderText;
@property (nonatomic, assign) ATFeedbackAttachmentOptions attachmentOptions;
@property (nonatomic, assign) BOOL showEmailAddressField;
@property (nonatomic, assign) BOOL deleteCurrentFeedbackOnCancel;

- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)donePressed:(id)sender;
- (IBAction)photoPressed:(id)sender;
- (IBAction)showInfoView:(id)sender;

- (void)presentFromViewController:(UIViewController *)presentingViewController animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)dismiss:(BOOL)animated;
- (void)unhide:(BOOL)animated;
@end
