//
//  CLMainWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 2/7/16.
//
//

#import "CLMainWindowController.h"

@interface CLMainWindowController ()

@end

@implementation CLMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    viewLayer.backgroundColor = CGColorCreateGenericRGB(255.0, 255.0, 255.0, 1); //RGB plus Alpha Channel
    [self.window.contentView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    (self.window.contentView).layer = viewLayer;
    self.window.titlebarAppearsTransparent = YES;
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
