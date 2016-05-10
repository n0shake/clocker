//
//  IKCodeAutoLayoutWindowController.m
//  ShortcutRecorderDemo
//
//  Created by Ilya Kulakov on 21.01.13.
//  Copyright (c) 2013 Ilya Kulakov. All rights reserved.
//

#import "IKCodeAutoLayoutWindowController.h"


@implementation IKCodeAutoLayoutWindowController

#pragma mark NSWindowController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    SRRecorderControl *pingShortcutRecorder = [[SRRecorderControl alloc] initWithFrame:NSZeroRect];
    pingShortcutRecorder.delegate = self;
    pingShortcutRecorder.enabled = NO;
    [pingShortcutRecorder setAllowedModifierFlags:NSShiftKeyMask | NSAlternateKeyMask | NSCommandKeyMask
                            requiredModifierFlags:0
                         allowsEmptyModifierFlags:NO];
    SRRecorderControl *globalPingShortcutRecorder = [[SRRecorderControl alloc] initWithFrame:NSZeroRect];
    globalPingShortcutRecorder.delegate = self;
    SRRecorderControl *pingItemShortcutRecorder = [[SRRecorderControl alloc] initWithFrame:NSZeroRect];
    pingItemShortcutRecorder.delegate = self;
    NSTextField *pingLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    pingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    pingLabel.font = [NSFont systemFontOfSize:13];
    pingLabel.editable = NO;
    pingLabel.selectable = NO;
    pingLabel.bezeled = NO;
    pingLabel.alignment = NSRightTextAlignment;
    pingLabel.stringValue = @"Ping Button:";
    pingLabel.drawsBackground = NO;
    [pingLabel setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSTextField *globalPingLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    globalPingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    globalPingLabel.font = [NSFont systemFontOfSize:13];
    globalPingLabel.editable = NO;
    globalPingLabel.selectable = NO;
    globalPingLabel.bezeled = NO;
    globalPingLabel.alignment = NSRightTextAlignment;
    globalPingLabel.stringValue = @"Global Ping:";
    globalPingLabel.drawsBackground = NO;
    [globalPingLabel setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSTextField *pingItemLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    pingItemLabel.translatesAutoresizingMaskIntoConstraints = NO;
    pingItemLabel.font = [NSFont systemFontOfSize:13];
    pingItemLabel.editable = NO;
    pingItemLabel.selectable = NO;
    pingItemLabel.bezeled = NO;
    pingItemLabel.alignment = NSRightTextAlignment;
    pingItemLabel.stringValue = @"Ping Item:";
    pingItemLabel.drawsBackground = NO;
    [pingItemLabel setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    NSView *v = self.window.contentView;
    [v addSubview:pingShortcutRecorder];
    [v addSubview:globalPingShortcutRecorder];
    [v addSubview:pingItemShortcutRecorder];    
    [v addSubview:pingLabel];
    [v addSubview:globalPingLabel];
    [v addSubview:pingItemLabel];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(pingShortcutRecorder,
                                                         globalPingShortcutRecorder,
                                                         pingItemShortcutRecorder,
                                                         pingLabel,
                                                         globalPingLabel,
                                                         pingItemLabel);
    [v addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[pingLabel(==80)]-[pingShortcutRecorder(>=100)]-|"
                                                              options:NSLayoutFormatAlignAllBaseline
                                                              metrics:nil
                                                                views:views]];
    [v addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[globalPingLabel(==pingLabel)]-[globalPingShortcutRecorder(==pingShortcutRecorder)]-|"
                                                              options:NSLayoutFormatAlignAllBaseline
                                                              metrics:nil
                                                                views:views]];
    [v addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[pingItemLabel(==pingLabel)]-[pingItemShortcutRecorder(==pingShortcutRecorder)]-|"
                                                              options:NSLayoutFormatAlignAllBaseline
                                                              metrics:nil
                                                                views:views]];
    [v addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[pingShortcutRecorder(==25)]-[globalPingShortcutRecorder(==25)]-[pingItemShortcutRecorder(==25)]-|"
                                                              options:0
                                                              metrics:nil
                                                                views:views]];
    
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    self.pingShortcutRecorder = pingShortcutRecorder;
    [self.pingShortcutRecorder bind:NSValueBinding
                           toObject:defaults
                        withKeyPath:@"values.ping"
                            options:nil];
    [self.pingShortcutRecorder bind:NSEnabledBinding
                           toObject:defaults
                        withKeyPath:@"values.isPingItemEnabled"
                            options:nil];
    self.globalPingShortcutRecorder = globalPingShortcutRecorder;
    [self.globalPingShortcutRecorder bind:NSValueBinding
                                 toObject:defaults
                              withKeyPath:@"values.globalPing"
                                  options:nil];
    self.pingItemShortcutRecorder = pingItemShortcutRecorder;
    [self.pingItemShortcutRecorder bind:NSValueBinding
                               toObject:defaults
                            withKeyPath:@"values.pingItem"
                                options:nil];
}

@end
