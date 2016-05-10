//
//  IKAppDelegate.h
//  ShortcutRecorderDemo
//
//  Created by ILya Kulakov on 18.01.13.
//  Copyright (c) 2013 Ilya Kulakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IKAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSButton *pingButton;

@property (assign) IBOutlet NSMenuItem *pingItem;

- (IBAction)showIBAutoLayout:(id)aSender;

- (IBAction)showCodeAutoLayout:(id)aSender;

- (IBAction)showAutoresizingMasks:(id)aSender;

- (IBAction)ping:(id)aSender;

@end
