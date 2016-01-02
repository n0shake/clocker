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
#import <Parse/Parse.h>

NSString *const CLParseApplicationID = @"F2ahd8J6sfjQMCc5z3xSy9kVK94PmKmH6hV2UsUK";
NSString *const CLParseClientID = @"vfnqDtinvmwUBkcifznYHzYTetxN5iMvt8Ey8StD";

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
    [iRate sharedInstance].appStoreID = 1056643111;
    [iVersion sharedInstance].appStoreID = 1056643111;
    [iRate sharedInstance].useAllAvailableLanguages = NO;
    [iVersion sharedInstance].useAllAvailableLanguages = NO;
    [[iRate sharedInstance] setVerboseLogging:YES];
    [[iVersion sharedInstance] setVerboseLogging:NO];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSNumber *opened = [[NSUserDefaults standardUserDefaults] objectForKey:@"noOfTimes"];
    if (opened == nil)
    {
         [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray array]
                                                   forKey:CLDefaultPreferenceKey];
        NSInteger noOfTimes = opened.integerValue + 1;
        NSNumber *noOfTime = [NSNumber numberWithInteger:noOfTimes];
        [[NSUserDefaults standardUserDefaults] setObject:noOfTime forKey:@"noOfTimes"];;
        
    }
    
    NSString *defaultTheme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (defaultTheme == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@"Default" forKey:CLThemeKey];
    }
    
    NSNumber *displaySuntimings = [[NSUserDefaults standardUserDefaults] objectForKey:CLDisplaySunTimingKey];
    if (displaySuntimings == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:1] forKey:CLDisplaySunTimingKey];
    }
    
    NSNumber *displayFutureSlider = [[NSUserDefaults standardUserDefaults] objectForKey:CLDisplayFutureSliderKey];
    if (displayFutureSlider == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:0] forKey:CLDisplayFutureSliderKey];
    }
    
    NSNumber *defaultTimeFormat = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    if (defaultTimeFormat == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:CL24hourFormatSelectedKey];
    }
    
    NSNumber *relativeDate = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    if (relativeDate == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLRelativeDateKey];
    }

    // Install icon into the menu bar
    self.menubarController = [[MenubarController alloc] init];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    
    [[Crashlytics sharedInstance] setDebugMode:NO];
    [Fabric with:@[[Crashlytics class]]];

    
    //Setting up Parse
    [Parse setApplicationId:CLParseApplicationID
                  clientKey:CLParseClientID];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
    
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
