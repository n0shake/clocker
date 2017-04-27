//
//  CLAboutUsViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import "CLAboutUsViewController.h"
#import "CommonStrings.h"
#import "CLAppFeedbackWindowController.h"
#import "CLUnderlinedButton.h"
#import <Crashlytics/Crashlytics.h>

@interface CLAboutUsViewController ()

@property (strong, nonatomic) CLAppFeedbackWindowController *feedbackWindow;
@property (weak) IBOutlet NSTextField *versionField;
@property (weak) IBOutlet CLUnderlinedButton *makerButton;
@property (weak) IBOutlet CLUnderlinedButton *quickCommentAction;
@property (weak) IBOutlet CLUnderlinedButton *privateFeedback;
@property (weak) IBOutlet CLUnderlinedButton *supportClocker;
@property (weak) IBOutlet CLUnderlinedButton *paypalButton;


@end

static CLAboutUsViewController *sharedAboutUs = nil;
NSString *const CLAboutUsNibIdentifier = @"CLAboutWindow";
NSString *const CLGitHubURL = @"https://github.com/Abhishaker17/Clocker/?ref=ClockerApp";
NSString *const CLIssueURL =@"https://github.com/Abhishaker17/Clocker/issues/?ref=ClockerApp";
NSString *const CLPayPalURL = @"https://www.paypal.me/AbhishekBanthia";
NSString *const CLTwitterLink = @"https://twitter.com/abgbm/?ref=ClockerApp";
NSString *const CLPersonalWebsite = @"http://abhishekbanthia.com/?ref=ClockerApp";

@implementation CLAboutUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self underlineTextForActionButton];
    
    self.versionField.stringValue = [NSString stringWithFormat:@"Clocker %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

    // Do view setup here.
}

- (void)underlineTextForActionButton
{
    NSMutableAttributedString *paypal = [[NSMutableAttributedString alloc] initWithAttributedString:self.paypalButton.attributedTitle];
    
    [paypal addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(paypal.length - 5, 4)];
    
    [self.paypalButton setAttributedTitle:paypal];
    
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:self.makerButton.attributedTitle];
    
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(3, str.length-3)];
    
    [self.makerButton setAttributedTitle:str];
    
    NSMutableAttributedString *quickComment = [[NSMutableAttributedString alloc] initWithAttributedString:self.quickCommentAction.attributedTitle];
    
    [quickComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(3, 6)];
    
    [self.quickCommentAction setAttributedTitle:quickComment];
     
     NSMutableAttributedString *privateFeed = [[NSMutableAttributedString alloc] initWithAttributedString:self.privateFeedback.attributedTitle];
     
     [privateFeed addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(7, privateFeed.length-7)];
     
     [self.privateFeedback setAttributedTitle:privateFeed];
    
    NSMutableAttributedString *supportClocker = [[NSMutableAttributedString alloc] initWithAttributedString:self.supportClocker.attributedTitle];
    
    [supportClocker addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(27, 19)];
    
    [self.supportClocker setAttributedTitle:supportClocker];
    
    [self.quickCommentAction setCursor:[NSCursor pointingHandCursor]];
    [self.supportClocker setCursor:[NSCursor pointingHandCursor]];
    [self.privateFeedback setCursor:[NSCursor pointingHandCursor]];
    [self.makerButton setCursor:[NSCursor pointingHandCursor]];
     [self.paypalButton setCursor:[NSCursor pointingHandCursor]];
}

- (IBAction)openMyTwitter:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLTwitterLink]];
    [Answers logCustomEventWithName:@"openedTwitterProfile" customAttributes:@{}];
}

- (IBAction)viewSource:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLGitHubURL]];
    [Answers logCustomEventWithName:@"openedGitHub" customAttributes:@{}];
}
- (IBAction)reportIssue:(id)sender
{
    self.feedbackWindow = [CLAppFeedbackWindowController sharedWindow];
    [self.feedbackWindow showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self.view.window orderOut:self];
    [Answers logCustomEventWithName:@"reportIssueOpened" customAttributes:@{}];
}

- (IBAction)openPaypal:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLPayPalURL]];
    [Answers logCustomEventWithName:@"openedPaypalPage" customAttributes:@{}];
}

- (IBAction)openWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLPersonalWebsite]];
     [Answers logCustomEventWithName:@"openedPersonalWebsite" customAttributes:@{}];
}

@end
