//  Created by Abhishek Banthia on 11/4/15.
//  Copyright (c) 2015 Abhishek Banthia All rights reserved.
//

// Copyright (c) 2015, Abhishek Banthia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ApplicationDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "iRate.h"
#import "CommonStrings.h"
#import "iVersion.h"
#import "CLOnboardingWindowController.h"

#define helperAppBundleIdentifier @"com.abhishek.Clocker-Helper" // change as appropriate to help app bundle identifier
#define terminateNotification @"TERMINATEHELPER" // can be basically any string

@implementation ApplicationDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;

#pragma mark -

- (void)dealloc
{
    [self.panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

#pragma mark -

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (void)initialize
{
    //Configure iRate
    [iRate sharedInstance].useAllAvailableLanguages = YES;
    [iVersion sharedInstance].useAllAvailableLanguages = YES;
    [[iRate sharedInstance] setVerboseLogging:YES];
    [[iVersion sharedInstance] setVerboseLogging:NO];
    [iRate sharedInstance].promptForNewVersionIfUserRated = YES;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    BOOL startedAtLogin = NO;
    
    NSNumber *opened = [[NSUserDefaults standardUserDefaults] objectForKey:@"noOfTimes"];
    if (opened == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray array]
                                                  forKey:CLDefaultPreferenceKey];
        NSInteger noOfTimes = opened.integerValue + 1;
        NSNumber *noOfTime = [NSNumber numberWithInteger:noOfTimes];
        [[NSUserDefaults standardUserDefaults] setObject:noOfTime forKey:@"noOfTimes"];;
        
    }
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    for (NSRunningApplication *app in apps)
    {
        if ([app.bundleIdentifier isEqualToString:helperAppBundleIdentifier])
        {
            startedAtLogin = YES;
            break;
        }
    }
    

    if (startedAtLogin)
    {
        [[NSDistributedNotificationCenter defaultCenter]
         postNotificationName:terminateNotification
                       object:[[NSBundle mainBundle] bundleIdentifier]];
    }
    
    // Install icon into the menu bar
    self.menubarController = [MenubarController new];
    
    [self initializeDefaults];

    NSString *onboarding = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialLaunch"];
    
    if (onboarding == nil)
    {
        CLOnboardingWindowController *windowController = [CLOnboardingWindowController sharedWindow];
        [windowController showWindow:nil];
        [NSApp activateIgnoringOtherApps:YES];
        [[NSUserDefaults standardUserDefaults] setObject:@"OnboardingDone" forKey:@"initialLaunch"];
        [self.menubarController setInitialTimezoneData];
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    
    [[Crashlytics sharedInstance] setDebugMode:NO];
    [Fabric with:@[[Crashlytics class]]];
    
}

- (void)initializeDefaults
{
    NSString *defaultTheme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (defaultTheme == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLThemeKey];
    }
    
    NSNumber *displayFutureSlider = [[NSUserDefaults standardUserDefaults] objectForKey:CLDisplayFutureSliderKey];
    if (displayFutureSlider == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:0] forKey:CLDisplayFutureSliderKey];
    }
    
    NSNumber *defaultTimeFormat = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    if (defaultTimeFormat == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:CL24hourFormatSelectedKey];
    }
    
    NSNumber *relativeDate = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    if (relativeDate == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLRelativeDateKey];
    }
    
    NSNumber *showDayInMenuBar = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowDayInMenu];
    if (showDayInMenuBar == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLShowDayInMenu];
    }
    
    NSNumber *showDateInMenu = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowDateInMenu];
    if (showDateInMenu == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:CLShowDateInMenu];
    }
    
    NSNumber *showCityInMenu = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowPlaceInMenu];
    if (showCityInMenu == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLShowPlaceInMenu];
    }
    
    NSNumber *showAppInForeground = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
    if (showAppInForeground == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLShowAppInForeground];
    }
    
    NSNumber *startClockerAtLogin = [[NSUserDefaults standardUserDefaults] objectForKey:CLStartAtLogin];
    if (startClockerAtLogin == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLStartAtLogin];
    }
    
    NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
    if (displayMode == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLShowAppInForeground];
    }
    
    //If mode selected is 1, then show the window when the app starts
    if (displayMode.integerValue == 1)
    {
        self.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [self.floatingWindow showWindow:nil];
        [self.floatingWindow.mainTableview reloadData];
        [self.floatingWindow startWindowTimer];
        
        [NSApp activateIgnoringOtherApps:YES];
    }
    


}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
    
    if (displayMode.integerValue == 1)
    {
        self.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [self.floatingWindow showWindow:nil];
        [self.floatingWindow startWindowTimer];
        [NSApp activateIgnoringOtherApps:YES];
        return;
    }
    
    
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - Public accessors

- (PanelController *)panelController
{
    if (_panelController == nil) {
        _panelController = [[PanelController alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end
