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

@interface CLAboutUsViewController ()

@property (strong, nonatomic) CLAppFeedbackWindowController *feedbackWindow;
@property (weak) IBOutlet NSTextField *versionField;

@end

static CLAboutUsViewController *sharedAboutUs = nil;
NSString *const CLAboutUsNibIdentifier = @"CLAboutWindow";
NSString *const CLGitHubURL = @"https://github.com/Abhishaker17/Clocker";
NSString *const CLIssueURL =@"https://github.com/Abhishaker17/Clocker/issues";
NSString *const CLFacebookPageURL = @"https://www.facebook.com/ClockerMenubarClock/";

@implementation CLAboutUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.versionField.stringValue = NSLocalizedFormatString(@"ClockerVersion", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);

    // Do view setup here.
}

- (IBAction)viewSource:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLGitHubURL]];
}
- (IBAction)reportIssue:(id)sender
{
    self.feedbackWindow = [CLAppFeedbackWindowController sharedWindow];
    [self.feedbackWindow showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self.view.window orderOut:self];
}

- (IBAction)openFacebookPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLFacebookPageURL]];
}

@end
