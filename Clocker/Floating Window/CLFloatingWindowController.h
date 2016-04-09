//
//  CLFloatingWindowController.h
//  Clocker
//
//  Created by Abhishek Banthia on 4/2/16.
//
//

#import <Cocoa/Cocoa.h>
#import "CLParentPanelController.h"

@interface CLFloatingWindowController : CLParentPanelController <NSTableViewDataSource>

+ (instancetype)sharedFloatingWindow;
- (void)updatePanelColor;

@end
