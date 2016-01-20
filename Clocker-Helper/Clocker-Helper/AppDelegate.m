//
//  AppDelegate.m
//  Clocker-Helper
//
//  Created by Abhishek Banthia on 1/19/16.
//  Copyright © 2016 Abhishek Banthia. All rights reserved.
//

#import "AppDelegate.h"
#define terminateNotification @"TerminateHelper" 
#define mainAppBundleIdentifier @"com.abhishek.Clocker" 

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(killApp)
                                                            name:terminateNotification
                                                          object:mainAppBundleIdentifier];

    
    BOOL alreadyRunning = NO;
    BOOL isActive = NO;
    
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"com.abhishek.Clocker"]) {
            alreadyRunning = YES;
             isActive = [app isActive];
            break;
        }
    }
    
    if (!alreadyRunning || !isActive) {
        NSString *path = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        NSLog(@"Path:%@", path);
        [[NSWorkspace sharedWorkspace] launchApplication:path];

    }
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)killApp
{
    [NSApp terminate:nil];
}

@end
