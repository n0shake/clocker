//
//  AppDelegate.m
//  Clocker-Helper
//
//  Created by Abhishek Banthia on 1/19/16.
//  Copyright © 2016 Abhishek Banthia. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *path = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    
    [[NSWorkspace sharedWorkspace] launchApplication:path];
    
    /*The Helper App's job is done!*/
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
