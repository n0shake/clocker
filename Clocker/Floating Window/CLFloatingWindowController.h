//
//  CLFloatingWindowController.h
//  Clocker
//
//  Created by Abhishek Banthia on 4/2/16.
//
//

#import <Cocoa/Cocoa.h>
#import "CLParentPanelController.h"

@interface CLFloatingWindowController : CLParentPanelController <NSTableViewDataSource, NSWindowDelegate>

@property (strong, nonatomic) NSTimer *floatingWindowTimer;

+ (instancetype)sharedFloatingWindow;
- (void)updatePanelColor;
- (void)startWindowTimer;


@end
