//
//  IKDemoWindowController.h
//  ShortcutRecorderDemo
//
//  Created by Ilya Kulakov on 18.01.13.
//  Copyright (c) 2013 Ilya Kulakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>


@interface IKDemoWindowController : NSWindowController <SRRecorderControlDelegate, SRValidatorDelegate>

@property (weak) IBOutlet SRRecorderControl *pingShortcutRecorder;

@property (weak) IBOutlet SRRecorderControl *globalPingShortcutRecorder;

@property (weak) IBOutlet SRRecorderControl *pingItemShortcutRecorder;

@end
