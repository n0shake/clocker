//
//  CLAboutUsViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import "CLAboutUsViewController.h"
#import <ApptentiveConnect/ATConnect.h>

@interface CLAboutUsViewController ()

@end

static CLAboutUsViewController *sharedAboutUs = nil;
NSString *const CLAboutUsNibIdentifier = @"CLAboutWindow";
NSString *const CLGitHubURL = @"https://github.com/Abhishaker17/Clocker";
NSString *const CLIssueURL =@"https://github.com/Abhishaker17/Clocker/issues";
NSString *const CLFacebookPageURL = @"https://www.facebook.com/ClockerMenubarClock/";

@implementation CLAboutUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];

    // Do view setup here.
}

- (IBAction)viewSource:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLGitHubURL]];
}
- (IBAction)reportIssue:(id)sender
{
    //
    ATConnect *connection = [ATConnect sharedConnection];
    [connection showFeedbackWindow:sender];
}

- (IBAction)openFacebookPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLFacebookPageURL]];
}


@end
