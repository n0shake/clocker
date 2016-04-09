//
//  CLOnboardingWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 1/19/16.
//
//

#import "CLOnboardingWindowController.h"
#import <QuartzCore/QuartzCore.h>

@interface CLOnboardingWindowController ()

@property (strong, nonatomic) CLIntroViewController *introViewController;

@end

static CLOnboardingWindowController *sharedOnboardingWindow;

@implementation CLOnboardingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    
    self.window.backgroundColor = [NSColor whiteColor];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}



+ (instancetype)sharedWindow
{
    if (sharedOnboardingWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedOnboardingWindow = [[self alloc] initWithWindowNibName:@"CLOnboardingWindow"];
            
        });
    }
    return sharedOnboardingWindow;
}

- (IBAction)continueButtonPressed:(id)sender
{

    self.introViewController = [[CLIntroViewController alloc] initWithNibName:@"CLIntroView" bundle:nil];
    [[self.window animator] setContentSize:self.introViewController.view.frame.size];
    [[self.window animator] setContentView:self.introViewController.view];
    
    CGFloat xPos = NSWidth([[self.window screen] frame])/2 - NSWidth([self.window frame])/2;
    CGFloat yPos = NSHeight([[self.window screen] frame])/2 - NSHeight([self.window frame])/2;
    [self.window setFrame:NSMakeRect(xPos, yPos, NSWidth([self.window frame]), NSHeight([self.window frame])) display:YES];
}


@end
