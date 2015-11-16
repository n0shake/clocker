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

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"noOfLaunches"] == nil)
    {
        NSNumber *numberOfLaunches = @1;
        [[NSUserDefaults standardUserDefaults] setObject:numberOfLaunches forKey:@"noOfLaunches"];
    }
    else
    {
        //Check the number of times app has been launched.
        
        NSNumber *numberOfLaunches = [[NSUserDefaults standardUserDefaults] objectForKey:@"noOfLaunches"];
        NSInteger launches = numberOfLaunches.integerValue;
        launches++;
        numberOfLaunches = [NSNumber numberWithInteger:launches];
        [[NSUserDefaults standardUserDefaults] setObject:numberOfLaunches forKey:@"noOfLaunches"];
        
        if (numberOfLaunches.integerValue == 5)
        {
            NSAlert *reviewAlert = [[NSAlert alloc] init];
            reviewAlert.alertStyle = NSInformationalAlertStyle;
            reviewAlert.messageText = @"Spead the word, maybe?";
            reviewAlert.informativeText = @"Clocker is completely open source. If it has helped you in any way, please leave a kind review on the App Store!";
            [reviewAlert addButtonWithTitle:@"Cancel"];
            [reviewAlert runModal];

        }
    }
    
    NSArray *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPreferences"];
    
    if (defaultPreference.count == 0)
    {
        NSMutableArray *newDefaults = [[NSMutableArray alloc] initWithObjects:[NSTimeZone systemTimeZone].name, nil];
        
        [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:@"defaultPreferences"];
    }

    
    // Install icon into the menu bar
    self.menubarController = [[MenubarController alloc] init];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    
    [[Crashlytics sharedInstance] setDebugMode:YES];
    [Fabric with:@[[Crashlytics class]]];
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
