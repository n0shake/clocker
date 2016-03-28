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
    
    NSString *path = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] launchApplication:path];
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
