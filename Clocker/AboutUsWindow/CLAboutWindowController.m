//
//  CLAboutWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/11/15.
//
//

#import "CLAboutWindowController.h"

@interface CLAboutWindowController ()

@end

static CLAboutWindowController *sharedAboutUs = nil;
NSString *const CLAboutUsWindowNibIdentifier = @"CLAboutWindow";
NSString *const CLSourceCodeURL = @"https://github.com/Abhishaker17/Clocker";
NSString *const CLIssueReportingURL =@"https://github.com/Abhishaker17/Clocker/issues";
NSString *const CLFacebookURL = @"https://www.facebook.com/ClockerMenubarClock/";

@implementation CLAboutWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedReference
{
    if (sharedAboutUs == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedAboutUs = [[self alloc] initWithWindowNibName:CLAboutUsWindowNibIdentifier];
            
        });
        
    }
    
    return sharedAboutUs;
}
- (IBAction)viewSource:(id)sender
{
      [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLSourceCodeURL]];
}
- (IBAction)reportIssue:(id)sender
{
    //
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLIssueReportingURL]];
}

- (IBAction)openFacebookPage:(id)sender
{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CLFacebookURL]];
}

@end
