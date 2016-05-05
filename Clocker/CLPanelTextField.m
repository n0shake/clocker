//
//  CLPanelTextField.m
//  Clocker
//
//  Created by Abhishek Banthia on 5/4/16.
//
//

#import "CLPanelTextField.h"
#import "CLFloatingWindowController.h"

@implementation CLPanelTextField

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    CLFloatingWindowController *windowController = [CLFloatingWindowController sharedFloatingWindow];
    
    [windowController.floatingWindowTimer pause];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    
    CLFloatingWindowController *windowController = [CLFloatingWindowController sharedFloatingWindow];
    
    [windowController.floatingWindowTimer pause];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

@end
