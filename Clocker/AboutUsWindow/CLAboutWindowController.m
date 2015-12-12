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
            sharedAboutUs = [[self alloc] initWithWindowNibName:@"CLAboutWindow"];
            
        });
        
    }
    
    return sharedAboutUs;
}
- (IBAction)viewSource:(id)sender
{
      [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Abhishaker17/Clocker"]];
}
- (IBAction)reportIssue:(id)sender
{
    //
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Abhishaker17/Clocker/issues"]];
}

- (IBAction)openFacebookPage:(id)sender
{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/ClockerMenubarClock/"]];
}

@end
