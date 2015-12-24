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
    
    self.window.backgroundColor = [NSColor whiteColor];
    
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
    [self.appearanceView.view removeFromSuperview];
    self.appearanceView = nil;
}

- (void)setWindowWithContentView:(NSView *)contentView
{
    [self.window setContentSize:contentView.frame.size];
    [self.window setContentView:contentView];
}

- (IBAction)openAboutUsView:(id)sender
{
    self.aboutUsView = [[CLAboutUsViewController alloc] initWithNibName:@"CLAboutUsView" bundle:nil];
    [self setWindowWithContentView:self.aboutUsView.view];
    [self.preferencesView.view removeFromSuperview];
    self.preferencesView = nil;
    [self.appearanceView.view removeFromSuperview];
    self.appearanceView = nil;
}

- (IBAction)openAppearanceView:(id)sender
{
    self.appearanceView = [[CLAppearanceViewController alloc] initWithNibName:@"CLAppearanceView" bundle:nil];
    [self setWindowWithContentView:self.appearanceView.view];
    [self.preferencesView.view removeFromSuperview];
    self.preferencesView = nil;
    [self.aboutUsView.view removeFromSuperview];
    self.aboutUsView = nil;
}

@end
