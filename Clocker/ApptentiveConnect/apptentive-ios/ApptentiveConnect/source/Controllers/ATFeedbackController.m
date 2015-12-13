//
//  ATFeedbackController.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ATFeedbackController.h"

#import "ATConnect_Private.h"
#import "ATContactStorage.h"
#import "ATCustomButton.h"
#import "ATToolbar.h"
#import "ATDefaultTextView.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATFeedback.h"
#import "ATFeedbackMetrics.h"
#import "ATHUDView.h"
#import "ATInfoViewController.h"
#import "ATSimpleImageViewController.h"
#import "ATUtilities.h"
#import "ATShadowView.h"

#define DEG_TO_RAD(angle) ((M_PI * angle) / 180.0)
#define RAD_TO_DEG(radians) (radians * (180.0/M_PI))

enum {
	kFeedbackPaperclipTag = 400,
	kFeedbackPaperclipBackgroundTag = 401,
	kFeedbackPhotoFrameTag = 402,
	kFeedbackPhotoControlTag = 403,
	kFeedbackPhotoPreviewTag = 404,
	kFeedbackPhotoFrameContainerTag = 405,
	kFeedbackPhotoHighlightTag = 406,
	kContainerViewTag = 1009,
	kATEmailAlertTextFieldTag = 1010,
	kFeedbackGradientLayerTag = 1011,
};

@interface ATFeedbackController (Private)
- (void)teardown;
- (void)setupFeedback;
- (BOOL)shouldReturn:(UIView *)view;
- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen;
- (UIWindow *)windowForViewController:(UIViewController *)viewController;
+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView;
+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window;
- (void)statusBarChanged:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (BOOL)shouldShowPaperclip;
- (BOOL)shouldShowThumbnail;
- (void)captureFeedbackState;
- (void)hide:(BOOL)animated;
- (void)finishHide;
- (void)finishUnhide;
- (CGRect)photoControlFrame;
- (CGFloat)attachmentVerticalOffset;
- (void)updateThumbnail;
- (void)updateThumbnailOffsetWithScale:(CGSize)scale;
- (void)sendFeedbackAndDismiss;
- (void)updateSendButtonState;
- (void)photoDragged:(UIPanGestureRecognizer *)recognizer;
@end

@interface ATFeedbackController (Positioning)
- (BOOL)isIPhoneAppInIPad;
- (CGRect)onscreenRectOfView;
- (CGPoint)offscreenPositionOfView;
- (void)positionInWindow;
@end

@implementation ATFeedbackController
@synthesize feedbackContainerView;
@synthesize window;
@synthesize doneButton;
@synthesize toolbar;
@synthesize redLineView;
@synthesize grayLineView;
@synthesize backgroundView;
@synthesize scrollView;
@synthesize emailField;
@synthesize feedbackView;
@synthesize logoControl;
@synthesize logoImageView;
@synthesize taglineLabel;
@synthesize attachmentOptions;
@synthesize feedback;
@synthesize customPlaceholderText;
@synthesize showEmailAddressField;
@synthesize deleteCurrentFeedbackOnCancel;

- (id)init {
	self = [super initWithNibName:@"ATFeedbackController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		showEmailAddressField = YES;
		startingStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
		self.attachmentOptions = ATFeedbackAllowPhotoAttachment | ATFeedbackAllowTakePhotoAttachment;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)setFeedback:(ATFeedback *)newFeedback {
	if (feedback != newFeedback) {
		[feedback release];
		feedback = nil;
		feedback = [newFeedback retain];
		[self setupFeedback];
	}
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	if (self.showEmailAddressField == NO) {
		CGRect emailFrame = [self.emailField frame];
		CGRect feedbackFrame = [self.feedbackContainerView frame];
		feedbackFrame.size.height += (feedbackFrame.origin.y - emailFrame.origin.y);
		feedbackFrame.origin.y = emailFrame.origin.y;
		[self.emailField setHidden:YES];
		[self.grayLineView setHidden:YES];
		[self.feedbackContainerView setFrame:feedbackFrame];
	}
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
	CALayer *l = self.view.layer;
	
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
	if (!parentWindow) {
		ATLogError(@"Unable to find parentWindow!");
	}
	if (originalPresentingWindow != parentWindow) {
		[originalPresentingWindow release], originalPresentingWindow = nil;
		originalPresentingWindow = [parentWindow retain];
	}
	CGRect animationBounds = CGRectZero;
	CGPoint animationCenter = CGPointZero;
	
	CGAffineTransform t = [ATFeedbackController viewTransformInWindow:parentWindow];
	self.window.transform = t;
	self.window.hidden = NO;
	[parentWindow resignKeyWindow];
	[self.window makeKeyAndVisible];
	animationBounds = parentWindow.bounds;
	animationCenter = parentWindow.center;
	
	
	// Animate in from above.
	self.window.bounds = animationBounds;
	self.window.windowLevel = UIWindowLevelNormal;
	CGPoint center = animationCenter;
	center.y = ceilf(center.y);
	
	CGRect endingFrame = [[UIScreen mainScreen] applicationFrame];
	
	[self positionInWindow];
	
	if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}
	
	self.window.center = CGPointMake(CGRectGetMidX(endingFrame), CGRectGetMidY(endingFrame));
	self.view.center = [self offscreenPositionOfView];
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	
	ATShadowView *shadowView = [[ATShadowView alloc] initWithFrame:self.window.bounds];
	shadowView.tag = kFeedbackGradientLayerTag;
	[self.window addSubview:shadowView];
	[self.window sendSubviewToBack:shadowView];
	shadowView.alpha = 1.0;
	
	l.cornerRadius = 10.0;
	l.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dialog_paper_bg"]].CGColor;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	}
	
	[UIView animateWithDuration:0.3 animations:^(void){
		self.view.center = newViewCenter;
		shadowView.alpha = 1.0;
	} completion:^(BOOL finished) {
		self.window.hidden = NO;
		if ([self.emailField.text isEqualToString:@""] && self.showEmailAddressField) {
			[self.emailField becomeFirstResponder];
		} else {
			[self.feedbackView becomeFirstResponder];
		}
	}];
	[shadowView release], shadowView = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidShowWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackWindowTypeFeedback] forKey:ATFeedbackWindowTypeKey]];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:self.feedbackView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenshotChanged:) name:ATImageViewChoseImage object:nil];
	
	self.redLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dotted_red_line"]];
	self.grayLineView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_gray_line"]];
	self.redLineView.opaque = NO;
	self.grayLineView.opaque = NO;
	self.redLineView.layer.opaque = NO;
	self.grayLineView.layer.opaque = NO;
	
	self.logoImageView.image = [ATBackend imageNamed:@"at_apptentive_icon_small"];
	self.taglineLabel.text = ATLocalizedString(@"Feedback Powered by Apptentive", @"Tagline text");
	if (![[ATConnect sharedConnection] showTagline]) {
		[self.logoControl setHidden:YES];
	}
	
	if ([self shouldShowPaperclip]) {
		CGRect viewBounds = self.view.bounds;
		UIImage *paperclipBackground = [ATBackend imageNamed:@"at_paperclip_background"];
		paperclipBackgroundView = [[UIImageView alloc] initWithImage:paperclipBackground];
		[self.view addSubview:paperclipBackgroundView];
		paperclipBackgroundView.frame = CGRectMake(viewBounds.size.width - paperclipBackground.size.width + 3.0, [self attachmentVerticalOffset] + 6.0, paperclipBackground.size.width, paperclipBackground.size.height);
		paperclipBackgroundView.tag = kFeedbackPaperclipBackgroundTag;
		paperclipBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		
		UIImage *paperclip = [ATBackend imageNamed:@"at_paperclip_foreground"];
		paperclipView = [[UIImageView alloc] initWithImage:paperclip];
		[self.view addSubview:paperclipView];
		paperclipView.frame = CGRectMake(viewBounds.size.width - paperclip.size.width + 6.0, [self attachmentVerticalOffset], paperclip.size.width, paperclip.size.height);
		paperclipView.tag = kFeedbackPaperclipTag;
		paperclipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		
		photoControl = [[UIControl alloc] initWithFrame:[self photoControlFrame]];
		photoControl.tag = kFeedbackPhotoControlTag;
		[photoControl addTarget:self action:@selector(photoPressed:) forControlEvents:UIControlEventTouchUpInside];
		photoControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:photoControl];
	}
	
	ATCustomButton *cancelButton = [[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleCancel];
	[cancelButton setAction:@selector(cancelFeedback:) forTarget:self];
	
	ATCustomButton *sendButton = [[ATCustomButton alloc] initWithButtonStyle:ATCustomButtonStyleSend];
	[sendButton setAction:@selector(donePressed:) forTarget:self];
	self.doneButton = sendButton;
	
	NSMutableArray *toolbarItems = [[self.toolbar items] mutableCopy];
	[toolbarItems insertObject:cancelButton atIndex:0];
	[toolbarItems addObject:sendButton];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.text = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.textColor = [UIColor colorWithRed:105/256. green:105/256. blue:105/256. alpha:1.0];
	titleLabel.shadowColor = [UIColor whiteColor];
	titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.minimumFontSize = 12;
	titleLabel.adjustsFontSizeToFitWidth = YES;
	titleLabel.opaque = NO;
	[titleLabel sizeToFit];
	CGRect titleFrame = titleLabel.frame;
	titleLabel.frame = titleFrame;
	
	UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
	[toolbarItems insertObject:titleButton atIndex:2];
	[titleButton release], titleButton = nil;
	[titleLabel release], titleLabel = nil;
	
	self.emailField.placeholder = ATLocalizedString(@"Email Address", @"Email Address Field Placeholder");
	
	if (self.customPlaceholderText) {
		self.feedbackView.placeholder = self.customPlaceholderText;
	} else {
		self.feedbackView.placeholder = ATLocalizedString(@"Feedback (required)", @"Feedback placeholder");
	}
	
	self.toolbar.items = toolbarItems;
	[toolbarItems release], toolbarItems = nil;
	[cancelButton release], cancelButton = nil;
	[sendButton release], sendButton = nil;
	
	[self setupFeedback];
	[self updateSendButtonState];
	[super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//	return YES;
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (IBAction)donePressed:(id)sender {
	[self captureFeedbackState];
	if (self.showEmailAddressField && (!self.feedback.email || [self.feedback.email length] == 0)) {
		self.window.windowLevel = UIWindowLevelNormal;
		NSString *title = ATLocalizedString(@"No email address?", @"Lack of email dialog title.");
		NSString *message = ATLocalizedString(@"We can't respond without one.", @"Lack of email dialog message.");
		UIAlertView *emailAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Feedback", @"Send button title"), nil];
		BOOL useNativeTextField = [emailAlert respondsToSelector:@selector(alertViewStyle)];
		UITextField *field = nil;
		
		if (useNativeTextField) {
			// iOS 5 and above.
			[emailAlert setAlertViewStyle:2]; // UIAlertViewStylePlainTextInput
			field = [emailAlert textFieldAtIndex:0];
			[field retain];
		} else {
			NSString *messagePadded = [NSString stringWithFormat:@"%@\n\n\n", message];
			[emailAlert setMessage:messagePadded];
			field = [[UITextField alloc] initWithFrame:CGRectMake(16, 83, 252, 25)];
			field.font = [UIFont systemFontOfSize:18];
			field.textColor = [UIColor lightGrayColor];
			field.backgroundColor = [UIColor clearColor];
			field.keyboardAppearance = UIKeyboardAppearanceAlert;
			field.borderStyle = UITextBorderStyleRoundedRect;
		}
		field.keyboardType = UIKeyboardTypeEmailAddress;
		field.delegate = self;
		field.autocapitalizationType = UITextAutocapitalizationTypeNone;
		field.placeholder = ATLocalizedString(@"Email Address", @"Email address popup placeholder text.");
		field.tag = kATEmailAlertTextFieldTag;
		
		if (!useNativeTextField) {
			[field becomeFirstResponder];
			[emailAlert addSubview:field];
		}
		[field release], field = nil;
		[emailAlert sizeToFit];
		[emailAlert show];
		[emailAlert release];
	} else {
		[self sendFeedbackAndDismiss];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackEventTappedSend] forKey:ATFeedbackWindowHideEventKey]];
}

- (IBAction)photoPressed:(id)sender {
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	[self hide:YES];
	[self captureFeedbackState];
	[self retain];
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	[presentingViewController presentModalViewController:vc animated:YES];
	[vc release];
}

- (IBAction)showInfoView:(id)sender {
	[self hide:YES];
	ATInfoViewController *vc = [[ATInfoViewController alloc] initWithFeedbackController:self];
	[presentingViewController presentModalViewController:vc animated:YES];
	[vc release];
}

- (IBAction)cancelFeedback:(id)sender {
	[self captureFeedbackState];
	[self dismiss:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATFeedbackDidHideWindowNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ATFeedbackEventTappedCancel] forKey:ATFeedbackWindowHideEventKey]];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[self captureFeedbackState];
	
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	CGPoint endingPoint = [self offscreenPositionOfView];
	
	UIView *gradientView = [self.window viewWithTag:kFeedbackGradientLayerTag];
	
	CGFloat duration = 0;
	if (animated) {
		duration = 0.3;
	}
	[UIView animateWithDuration:duration animations:^(void){
		self.view.center = endingPoint;
		gradientView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.emailField resignFirstResponder];
		[self.feedbackView resignFirstResponder];
		UIView *gradientView = [self.window viewWithTag:kFeedbackGradientLayerTag];
		[gradientView removeFromSuperview];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[presentingViewController.view setUserInteractionEnabled:YES];
		[self.window resignKeyWindow];
		[self.window removeFromSuperview];
		self.window.hidden = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:startingStatusBarStyle];
		[self teardown];
		[self release];

		if (completion) {
			completion();
		}
		[[ATConnect sharedConnection] feedbackControllerDidDismiss];
	}];
}

- (void)dismiss:(BOOL)animated {
	[self dismissAnimated:animated completion:nil];
}

- (void)unhide:(BOOL)animated {
	self.window.windowLevel = UIWindowLevelNormal;
	self.window.hidden = NO;
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 1.0;
		} completion:^(BOOL complete){
			[self finishUnhide];
		}];
	} else {
		[self finishUnhide];
	}
}

#pragma mark ATSimpleImageViewControllerDelegate
- (void)imageViewController:(ATSimpleImageViewController *)vc pickedImage:(UIImage *)image fromSource:(ATFeedbackImageSource)source {
	self.feedback.imageSource = source;
	[self.feedback setScreenshot:image];
}

- (void)imageViewControllerWillDismiss:(ATSimpleImageViewController *)vc animated:(BOOL)animated {
	[self unhide:animated];
	[self release];
}

- (ATFeedbackAttachmentOptions)attachmentOptionsForImageViewController:(ATSimpleImageViewController *)vc {
	return self.attachmentOptions;
}

- (UIImage *)defaultImageForImageViewController:(ATSimpleImageViewController *)vc {
	if ([self.feedback hasScreenshot]) {
		return [[self.feedback copyScreenshot] autorelease];
	}
	return nil;
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return [self shouldReturn:textField];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	UITextField *textField = (UITextField *)[alertView viewWithTag:kATEmailAlertTextFieldTag];
	if (textField) {
		self.feedback.email = textField.text;
		[self sendFeedbackAndDismiss];
	}
}
@end

@implementation ATFeedbackController (Private)

- (void)teardown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.window removeFromSuperview];
	self.window = nil;
	
	[paperclipBackgroundView removeFromSuperview];
	[paperclipBackgroundView release], paperclipBackgroundView = nil;
	
	[paperclipView removeFromSuperview];
	[paperclipView release], paperclipView = nil;
	
	[photoControl removeFromSuperview];
	[photoControl release], photoControl = nil;
	
	[photoFrameContainerView removeFromSuperview];
	[photoFrameContainerView release], photoFrameContainerView = nil;
	
	[feedbackContainerView release], feedbackContainerView = nil;
	
	self.doneButton = nil;
	self.toolbar = nil;
	self.redLineView = nil;
	self.grayLineView = nil;
	self.backgroundView = nil;
	self.scrollView = nil;
	self.emailField = nil;
	self.feedbackView = nil;
	self.logoControl = nil;
	self.logoImageView = nil;
	self.taglineLabel = nil;
	self.feedback = nil;
	self.customPlaceholderText = nil;
	[currentImage release], currentImage = nil;
	[originalPresentingWindow makeKeyWindow];
	[presentingViewController release], presentingViewController = nil;
	[originalPresentingWindow release], originalPresentingWindow = nil;
	if (self.deleteCurrentFeedbackOnCancel) {
		[[ATBackend sharedBackend] setCurrentFeedback:nil];
	}
}

- (void)setupFeedback {
	if (self.feedbackView && [self.feedbackView isDefault] && self.feedback.text) {
		self.feedbackView.text = self.feedback.text;
	}
	if (self.emailField && (!self.emailField.text || [@"" isEqualToString:self.emailField.text]) && self.feedback.email) {
		self.emailField.text = self.feedback.email;
	}
	if ([self isViewLoaded]) {
		// Avoid touching self.view before viewDidLoad.
		[self updateThumbnail];
	}
}

- (BOOL)shouldReturn:(UIView *)view {
	if (view == self.emailField) {
		[self.feedbackView becomeFirstResponder];
		return NO;
	} else if (view == self.feedbackView) {
		[self.feedbackView resignFirstResponder];
		return YES;
	}
	return YES;
}

- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen {
	UIApplication *application = [UIApplication sharedApplication];
	for (UIWindow *tmpWindow in [[application windows] reverseObjectEnumerator]) {
		if (tmpWindow.rootViewController || tmpWindow.isKeyWindow) {
			if (preferMainScreen && [tmpWindow respondsToSelector:@selector(screen)]) {
				if (tmpWindow.screen && [tmpWindow.screen isEqual:[UIScreen mainScreen]]) {
					return tmpWindow;
				}
			} else {
				return tmpWindow;
			}
		}
	}
	return nil;
}

- (UIWindow *)windowForViewController:(UIViewController *)viewController {
	UIWindow *result = nil;
	UIView *rootView = [viewController view];
	if (rootView.window) {
		result = rootView.window;
	}
	if (!result) {
		result = [self findMainWindowPreferringMainScreen:YES];
		if (!result) {
			result = [self findMainWindowPreferringMainScreen:NO];
		}
	}
	return result;
}

+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView {
	CGAffineTransform t = leafView.transform;
	UIView *s = leafView.superview;
	while (s && s != leafView.window) {
		t = CGAffineTransformConcat(t, s.transform);
		s = s.superview;
	}
	return atan2(t.b, t.a);
}

+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window {
	CGAffineTransform result = CGAffineTransformIdentity;
	do { // once
		if (!window) break;
		
		if ([[window rootViewController] view]) {
			CGFloat rotation = [ATFeedbackController rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
			result = CGAffineTransformMakeRotation(rotation);
			break;
		}
		
		if ([[window subviews] count]) {
			for (UIView *v in [window subviews]) {
				if (!CGAffineTransformIsIdentity(v.transform)) {
					result = v.transform;
					break;
				}
			}
		}
	} while (NO);
	return result;
}

- (void)statusBarChanged:(NSNotification *)notification {
	[self positionInWindow];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (self.window.hidden == NO) {
		[self retain];
		[self unhide:NO];
	}
	[pool release], pool = nil;
}

- (BOOL)shouldShowPaperclip {
	return (attachmentOptions != 0);
}

- (BOOL)shouldShowThumbnail {
	return [feedback hasScreenshot];
}

- (void)feedbackChanged:(NSNotification *)notification {
	if (notification.object == self.feedbackView) {
		[self updateSendButtonState];
	}
}

- (void)contactInfoChanged:(NSNotification *)notification {
	ATContactStorage *contact = [ATContactStorage sharedContactStorage];
	if (contact.name) {
		feedback.name = contact.name;
	}
	if (contact.phone) {
		feedback.phone = contact.phone;
	}
	if (contact.email) {
		feedback.email = contact.email;
	}
}

- (void)screenshotChanged:(NSNotification *)notification {
	if ([self.feedback hasScreenshot]) {
		[self updateThumbnail];
	} 
}

- (void)captureFeedbackState {
	self.feedback.text = self.feedbackView.text;
	self.feedback.email = self.emailField.text;
}


- (void)hide:(BOOL)animated {
	[self retain];
	
	self.window.windowLevel = UIWindowLevelNormal;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 0.0;
		} completion:^(BOOL finished) {
			[self finishHide];
		}];
	} else {
		[self finishHide];
	}
}

- (void)finishHide {
	self.window.alpha = 0.0;
	self.window.hidden = YES;
	[self.emailField resignFirstResponder];
	[self.feedbackView resignFirstResponder];
	[self.window removeFromSuperview];
}

- (void)finishUnhide {
	[self updateThumbnail];
	self.window.alpha = 1.0;
	[self.window makeKeyAndVisible];
	[self positionInWindow];
	if (self.showEmailAddressField) {
		[self.emailField becomeFirstResponder];
	} else {
		[self.feedbackView becomeFirstResponder];
	}
	[self release];
}


- (CGRect)photoControlFrame {
	if ([self shouldShowThumbnail] && [self shouldShowPaperclip]) {
		return photoFrameContainerView.frame;
	} else {
		CGRect f = paperclipView.frame;
		f.size.height += 10;
		return f;
	}
}

- (CGFloat)attachmentVerticalOffset {
	return self.toolbar.bounds.size.height - 4.0;
}

- (void)updateThumbnail {
	@synchronized(self) {
		if (photoPanRecognizer) {
			[photoPanRecognizer release], photoPanRecognizer = nil;
		}
		if ([self shouldShowPaperclip]) {
			UIImage *image = [feedback copyScreenshot];
			UIImageView *thumbnailView = nil;
			
			CGRect paperclipBackgroundFrame = paperclipBackgroundView.frame;
			paperclipBackgroundFrame.origin.y = [self attachmentVerticalOffset] + 6.0;
			paperclipBackgroundView.frame = paperclipBackgroundFrame;
			
			CGRect paperclipFrame = paperclipView.frame;
			paperclipFrame.origin.y = [self attachmentVerticalOffset];
			paperclipView.frame = paperclipFrame;
			
			if (image == nil) {
				[currentImage release], currentImage = nil;
				if (photoFrameContainerView != nil) {
					[photoFrameContainerView removeFromSuperview];
					[photoFrameContainerView release], photoFrameContainerView = nil;
				}
				photoControl.transform = paperclipView.transform;
				photoControl.frame = [self photoControlFrame];
			} else {
				if (photoFrameContainerView == nil) {
					CGRect viewBounds = self.view.bounds;
					UIImage *photoFrameImage = [ATBackend imageNamed:@"at_photo"];
					CGRect photoFrameContainerFrame = CGRectMake(viewBounds.size.width - photoFrameImage.size.width - 2.0, [self attachmentVerticalOffset], photoFrameImage.size.width, photoFrameImage.size.height);
					photoFrameContainerView = [[UIView alloc] initWithFrame:photoFrameContainerFrame];
					photoFrameContainerView.tag = kFeedbackPhotoFrameContainerTag;
					[self.view addSubview:photoFrameContainerView];
					
					UIImageView *photoFrameView = [[[UIImageView alloc] initWithImage:photoFrameImage] autorelease];
					photoFrameView.tag = kFeedbackPhotoFrameTag;
					
					[photoFrameContainerView addSubview:photoFrameView];
					photoFrameContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
				}
				CGRect photoFrameFrame = photoFrameContainerView.frame;
				photoFrameFrame.origin.y = [self attachmentVerticalOffset];
				photoFrameContainerView.frame = photoFrameFrame;
				thumbnailView = (UIImageView *)[photoFrameContainerView viewWithTag:kFeedbackPhotoPreviewTag];
				photoFrameTransform = photoFrameContainerView.transform;
				
				if (thumbnailView == nil) {
					thumbnailView = [[[UIImageView alloc] init] autorelease];
					thumbnailView.tag = kFeedbackPhotoPreviewTag;
					thumbnailView.contentMode = UIViewContentModeTop;
					thumbnailView.clipsToBounds = YES;
					
					UIView *highlightView = [[[UIView alloc] initWithFrame:thumbnailView.frame] autorelease];
					highlightView.tag = kFeedbackPhotoHighlightTag;
					
					//thumbnailView.backgroundColor = [UIColor blackColor];
					[photoFrameContainerView addSubview:thumbnailView];
					[photoFrameContainerView sendSubviewToBack:thumbnailView];
					[photoFrameContainerView addSubview:highlightView];
					[photoFrameContainerView bringSubviewToFront:highlightView];
					
					[self.view bringSubviewToFront:paperclipBackgroundView];
					[self.view bringSubviewToFront:photoFrameContainerView];
					[self.view bringSubviewToFront:paperclipView];
					[self.view bringSubviewToFront:photoControl];
					
					thumbnailView.transform = CGAffineTransformMakeRotation(DEG_TO_RAD(3.5));
				}
				
				photoFrameContainerView.alpha = 1.0;
				CGFloat scale = [[UIScreen mainScreen] scale];
				
				if (![image isEqual:currentImage]) {
					[currentImage release], currentImage = nil;
					currentImage = [image retain];
					CGSize imageSize = image.size;
					CGSize scaledImageSize = imageSize;
					CGFloat fitDimension = 70.0 * scale;
					
					if (imageSize.width > imageSize.height) {
						scaledImageSize.height = fitDimension;
						scaledImageSize.width = (fitDimension/imageSize.height) * imageSize.width;
					} else {
						scaledImageSize.height = (fitDimension/imageSize.width) * imageSize.height;
						scaledImageSize.width = fitDimension;
					}
					UIImage *scaledImage = [ATUtilities imageByScalingImage:image toSize:scaledImageSize scale:scale fromITouchCamera:(feedback.imageSource == ATFeedbackImageSourceCamera)];
					thumbnailView.bounds = CGRectMake(0.0, 0.0, 70.0, 70.0);
					thumbnailView.image = scaledImage;
				}
				CGRect f = CGRectMake(11.5, 11.5, 70, 70);
				thumbnailView.frame = f;
				thumbnailView.bounds = CGRectMake(0.0, 0.0, 70.0, 70.0);
				UIView *updatingHighlightView = [photoFrameContainerView viewWithTag:kFeedbackPhotoHighlightTag];
				CGRect highlightFrame = thumbnailView.frame;
				highlightFrame.origin.x += 5;
				highlightFrame.origin.y += 1;
				highlightFrame.size.width -= 10;
				highlightFrame.size.height -= 1;
				updatingHighlightView.frame = highlightFrame;
				updatingHighlightView.transform = thumbnailView.transform;
				
				photoControl.frame = [self photoControlFrame];
				photoControl.transform = photoFrameContainerView.transform;
				
				photoPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(photoDragged:)];
				photoPanRecognizer.minimumNumberOfTouches = 1;
				photoPanRecognizer.maximumNumberOfTouches = 1;
				photoPanRecognizer.delaysTouchesBegan = YES;
				photoPanRecognizer.cancelsTouchesInView = YES;
				[photoControl addGestureRecognizer:photoPanRecognizer];
				[image release], image = nil;
			}
		}
	}
}

- (void)updateThumbnailOffsetWithScale:(CGSize)scale {
	@synchronized(self) {
		if ([self shouldShowPaperclip]) {
			CGAffineTransform newPhotoFrameTransform = photoFrameTransform;
			if (!CGPointEqualToPoint(CGPointZero, photoDragOffset)) {
				newPhotoFrameTransform = CGAffineTransformTranslate(newPhotoFrameTransform, photoDragOffset.x, photoDragOffset.y);
			}
			if (!CGSizeEqualToSize(CGSizeZero, scale)) {
				newPhotoFrameTransform = CGAffineTransformScale(newPhotoFrameTransform, scale.width, scale.height);
			}
			photoControl.transform = newPhotoFrameTransform;
			photoFrameContainerView.transform = newPhotoFrameTransform;
		}
	}
}

- (void)sendFeedbackAndDismiss {
	[[ATBackend sharedBackend] sendFeedback:self.feedback];
	UIWindow *parentWindow = originalPresentingWindow;
	if (parentWindow) {
		ATHUDView *hud = [[ATHUDView alloc] initWithWindow:parentWindow];
		hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting feedback.");
		[hud show];
		[hud autorelease];
	}
	
	[self dismiss:YES];
}

- (void)updateSendButtonState {
	NSString *trimmedText = [self.feedbackView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	BOOL empty = [trimmedText length] == 0;
	self.doneButton.enabled = !empty;
	self.doneButton.style = empty == YES ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone;
}

- (void)photoDragged:(UIPanGestureRecognizer *)recognizer {
	CGFloat dragDistance = 75;
	if (recognizer == photoPanRecognizer) {
		if (recognizer.state == UIGestureRecognizerStateCancelled) {
			photoDragOffset = CGPointZero;
			[self updateThumbnailOffsetWithScale:CGSizeZero];
		} else if (recognizer.state == UIGestureRecognizerStateBegan) {
			photoDragOffset = CGPointZero;
			[self updateThumbnailOffsetWithScale:CGSizeZero];
		} else if (recognizer.state == UIGestureRecognizerStateChanged) {
			CGPoint translation = [recognizer translationInView:self.view];
			UIView *highlightView = [photoFrameContainerView viewWithTag:kFeedbackPhotoHighlightTag];
			translation.x = MIN(8, translation.x);
			photoDragOffset = translation;
			CGFloat distance = sqrt(photoDragOffset.x*photoDragOffset.x + photoDragOffset.y*photoDragOffset.y);
			if (distance > dragDistance) {
				highlightView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
			} else {
				highlightView.backgroundColor = [UIColor clearColor];
			}
			[self updateThumbnailOffsetWithScale:CGSizeZero];
		} else if (recognizer.state == UIGestureRecognizerStateEnded) {
			CGFloat distance = sqrt(photoDragOffset.x*photoDragOffset.x + photoDragOffset.y*photoDragOffset.y);
			if (distance > dragDistance) {
				[UIView animateWithDuration:0.3 animations:^(void){
					[self updateThumbnailOffsetWithScale:CGSizeMake(2, 2)];
					photoFrameContainerView.alpha = 0.0;
				} completion:^(BOOL complete){
					[self.feedback setScreenshot:nil];
					photoDragOffset = CGPointZero;
					[self updateThumbnail];
				}];
			} else {
				[UIView animateWithDuration:0.3 animations:^(void){
					photoDragOffset = CGPointZero;
					[self updateThumbnailOffsetWithScale:CGSizeZero];
				} completion:^(BOOL complete){
					// do nothing
				}];
			}
		}
	}
}
@end


@implementation ATFeedbackController (Positioning)
- (BOOL)isIPhoneAppInIPad {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model isEqualToString:@"iPad"]) {
			return YES;
		}
	}
	return NO;
}

- (CGRect)onscreenRectOfView {
	BOOL constrainViewWidth = [self isIPhoneAppInIPad];
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat w = statusBarSize.width;
	CGFloat h = statusBarSize.height;
	if (CGSizeEqualToSize(CGSizeZero, statusBarSize)) {
		w = screenBounds.size.width;
		h = screenBounds.size.height;
	}
	
	BOOL isLandscape = NO;
	
	CGFloat windowWidth = 0.0;
	
	switch (orientation) { 
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isLandscape = YES;
			windowWidth = h;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
		case UIInterfaceOrientationPortrait:
		default:
			windowWidth = w;
			break;
	}
	
	CGFloat viewHeight = 0.0;
	CGFloat viewWidth = 0.0;
	CGFloat originY = 0.0;
	CGFloat originX = 0.0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		viewHeight = isLandscape ? 368.0 : 368.0;
		originY = isLandscape ? 20.0 : 200;
		viewWidth = windowWidth - 12*2 - 100.0;
		originX = floorf((windowWidth - viewWidth)/2.0);
	} else {
		CGFloat landscapeKeyboardHeight = 162;
		CGFloat portraitKeyboardHeight = 216;
		viewHeight = self.view.window.bounds.size.height - (isLandscape ? landscapeKeyboardHeight + 8 - 37 : portraitKeyboardHeight + 8);
		viewWidth = windowWidth - 12;
		originX = 6.0;
		if (constrainViewWidth) {
			viewWidth = MIN(320, windowWidth - 12);
		}
	}
	
	CGRect f = self.view.frame;
	f.origin.y = originY;
	f.origin.x = originX;
	f.size.width = viewWidth;
	f.size.height = viewHeight;
	
	return f;
}

- (CGPoint)offscreenPositionOfView {
	CGRect f = [self onscreenRectOfView];
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGFloat statusBarHeight = MIN(statusBarSize.height, statusBarSize.width);
	CGFloat viewHeight = f.size.height;
	
	CGRect offscreenViewRect = f;
	offscreenViewRect.origin.y = -(viewHeight + statusBarHeight);
	CGPoint offscreenPoint = CGPointMake(CGRectGetMidX(offscreenViewRect), CGRectGetMidY(offscreenViewRect));
	
	return offscreenPoint;
}

- (void)positionInWindow {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	CGFloat angle = 0.0;
	CGRect newFrame = originalPresentingWindow.bounds;
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	
	switch (orientation) { 
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI; 
			newFrame.size.height -= statusBarSize.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = - M_PI / 2.0f;
			newFrame.origin.x += statusBarSize.width;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI / 2.0f;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			angle = 0.0;
			newFrame.origin.y += statusBarSize.height;
			newFrame.size.height -= statusBarSize.height;
			break;
	}
	[self.toolbar sizeToFit];
	
	CGRect toolbarBounds = self.toolbar.bounds;
	UIView *containerView = [self.view viewWithTag:kContainerViewTag];
	if (containerView != nil) {
		CGRect containerFrame = containerView.frame;
		containerFrame.origin.y = toolbarBounds.size.height;
		containerFrame.size.height = self.view.bounds.size.height - toolbarBounds.size.height;
		containerView.frame = containerFrame;
	}
	
	self.window.transform = CGAffineTransformMakeRotation(angle);
	self.window.frame = newFrame;
	CGRect onscreenRect = [self onscreenRectOfView];
	CGFloat viewWidth = onscreenRect.size.width;
	self.view.frame = onscreenRect;
	
	CGRect feedbackViewFrame = self.feedbackView.frame;
	feedbackViewFrame.origin.x = 0.0;
	
	// Either email field is shown and there's a thumbnail, or email is hidden.
	BOOL textIsBlockedByPaperclip = NO;
	if ([self shouldShowPaperclip] && [self shouldShowThumbnail]) {
		textIsBlockedByPaperclip = YES;
	} else if ([self shouldShowPaperclip] && ![self showEmailAddressField]) {
		textIsBlockedByPaperclip = YES;
	}
	if (textIsBlockedByPaperclip) {
		feedbackViewFrame.size.width = viewWidth - 100;
		self.feedbackView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, -100.0);
	} else {
		feedbackViewFrame.size.width = viewWidth;
		self.feedbackView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
	}
	self.feedbackView.frame = feedbackViewFrame;
	
	[self updateThumbnail];
}
@end
