//
//  CLOneWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import "CLOneWindowController.h"

NSString *const CLOneWindowNibIdentifier = @"CLOneWindow";

@interface CLOneWindowController ()

@end

@implementation CLOneWindowController

static CLOneWindowController *sharedWindow = nil;

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    
    [self openPreferences:nil];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedWindow
{
    if (sharedWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedWindow = [[self alloc] initWithWindowNibName:CLOneWindowNibIdentifier];
            
        });
    }
    return sharedWindow;
}

- (IBAction)openPreferences:(id)sender
{

    self.preferencesView = [[CLPreferencesViewController alloc] initWithNibName:@"CLPreferencesView" bundle:nil];
    [self setWindowWithContentView:self.preferencesView.view];
    [self.aboutUsView.view removeFromSuperview];
    self.aboutUsView = nil;
}

- (void)setWindowWithContentView:(NSView *)contentView
{
    [self.window setContentSize:contentView.frame.size];
    [self.window setContentView:contentView];
}

- (IBAction)openAboutUsView:(id)sender
{
    [self.preferencesView.view removeFromSuperview];
    self.preferencesView = nil;
    self.aboutUsView = [[CLAboutUsViewController alloc] initWithNibName:@"CLAboutUsView" bundle:nil];
    [self setWindowWithContentView:self.aboutUsView.view];

}

@end
