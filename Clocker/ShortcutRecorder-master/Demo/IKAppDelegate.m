//
//  IKAppDelegate.m
//  ShortcutRecorderDemo
//
//  Created by Ilya Kulakov on 18.01.13.
//  Copyright (c) 2013 Ilya Kulakov. All rights reserved.
//

#import <ShortcutRecorder/ShortcutRecorder.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey+ShortcutRecorder.h>
#import "IKAppDelegate.h"
#import "IKIBAutoLayoutWindowController.h"
#import "IKCodeAutoLayoutWindowController.h"
#import "IKIBAutoresizingMasksWindowController.h"


@implementation IKAppDelegate
{
    IKIBAutoLayoutWindowController *_ibAutoLayoutWindowController;
    IKCodeAutoLayoutWindowController *_codeAutoLayoutWindowController;
    IKIBAutoresizingMasksWindowController *_ibAutoresizingMasksWindowController;
}

- (void)dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.globalPing"];
}

#pragma mark Methods

- (IBAction)showIBAutoLayout:(id)aSender
{
    if (!_ibAutoLayoutWindowController)
        _ibAutoLayoutWindowController = [[IKIBAutoLayoutWindowController alloc] initWithWindowNibName:@"IKIBAutoLayoutWindowController"];
    
    [_ibAutoLayoutWindowController showWindow:aSender];
}

- (void)showCodeAutoLayout:(id)aSender
{
    if (!_codeAutoLayoutWindowController)
        _codeAutoLayoutWindowController = [[IKCodeAutoLayoutWindowController alloc] initWithWindowNibName:@"IKCodeAutoLayoutWindowController"];
    
    [_codeAutoLayoutWindowController showWindow:aSender];
}

- (void)showAutoresizingMasks:(id)aSender
{
    if (!_ibAutoresizingMasksWindowController)
        _ibAutoresizingMasksWindowController = [[IKIBAutoresizingMasksWindowController alloc] initWithWindowNibName:@"IKIBAutoresizingMasksWindowController"];
    
    [_ibAutoresizingMasksWindowController showWindow:aSender];
}

- (IBAction)ping:(id)aSender
{
    [[NSSound soundNamed:@"Ping"] play];
}


#pragma mark NSApplicationDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:self];
}


#pragma mark NSObject

- (void)awakeFromNib
{
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];

    [self.pingButton bind:@"keyEquivalent"
                 toObject:defaults
              withKeyPath:@"values.ping"
                  options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [self.pingButton bind:@"keyEquivalentModifierMask"
                 toObject:defaults
              withKeyPath:@"values.ping"
                  options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];

    [self.pingItem bind:@"keyEquivalent"
               toObject:defaults
            withKeyPath:@"values.pingItem"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [self.pingItem bind:@"keyEquivalentModifierMask"
               toObject:defaults
            withKeyPath:@"values.pingItem"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];

    [defaults addObserver:self forKeyPath:@"values.globalPing" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"values.globalPing"])
    {
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];
        
        NSDictionary *newShortcut = [anObject valueForKeyPath:aKeyPath];
        
        if (newShortcut && (NSNull *)newShortcut != [NSNull null])
        {
            PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath
                                                        keyCombo:newShortcut
                                                          target:self
                                                          action:@selector(ping:)];
            [hotKeyCenter registerHotKey:newHotKey];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
