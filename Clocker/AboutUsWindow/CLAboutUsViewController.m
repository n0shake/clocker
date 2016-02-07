//
//  CLAboutUsViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import "CLAboutUsViewController.h"
#import <Parse/Parse.h>

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
    
    self.versionField.stringValue = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];

    // Do view setup here.
}

- (IBAction)viewSource:(id)sender
{
    PFObject *aboutView = [PFObject objectWithClassName:@"CLAboutViews"];
    aboutView[@"GitHub"] = @"YES";
    aboutView[@"UniqueID"] = [self getSerialNumber];
    [aboutView saveEventually];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLGitHubURL]];
}
- (IBAction)reportIssue:(id)sender
{
    PFObject *aboutView = [PFObject objectWithClassName:@"CLAboutViews"];
    aboutView[@"ReportIssue"] = @"YES";
    aboutView[@"UniqueID"] = [self getSerialNumber];
    [aboutView saveEventually];
    self.feedbackWindow = [CLAppFeedbackWindowController sharedWindow];
    [self.feedbackWindow showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self.view.window orderOut:self];
}

- (IBAction)openFacebookPage:(id)sender
{
    PFObject *aboutView = [PFObject objectWithClassName:@"CLAboutViews"];
    aboutView[@"FacebookPage"] = @"YES";
    aboutView[@"UniqueID"] = [self getSerialNumber];
    [aboutView saveEventually];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLFacebookPageURL]];
}

- (NSString *)getSerialNumber
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}


@end
