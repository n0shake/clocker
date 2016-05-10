//
//  CLArrowIndicators.m
//  Clocker
//
//  Created by Abhishek Banthia on 5/9/16.
//
//

#import "CLArrowIndicators.h"

typedef enum : NSUInteger {
    Left,
    Right
} Type;

@implementation CLArrowIndicators

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
//    let drawRightArrow = self.type == .Right
//    let lineWidth: CGFloat = 4
//    
//    let bezierPath = NSBezierPath()
//    bezierPath.moveToPoint(NSPoint(x: drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), y: NSMaxY(self.bounds)))
//    bezierPath.lineToPoint(NSPoint(x: drawRightArrow ? NSMaxX(self.bounds)-lineWidth*0.5 : NSMinX(self.bounds)+lineWidth*0.5, y: NSMidY(self.bounds)))
//    bezierPath.lineToPoint(NSPoint(x: drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), y: NSMinY(self.bounds)))
//    bezierPath.lineWidth = lineWidth
//    bezierPath.lineCapStyle = .RoundLineCapStyle
//    bezierPath.lineJoinStyle = .RoundLineJoinStyle
//    (self.mouseDown ? self.color : self.color.colorWithAlphaComponent(0.33)).setStroke()
//    bezierPath.stroke()
    
    Type drawRightArrow = Right;
    CGFloat lineWidth = 4;
    
    NSBezierPath *bezierPath = [[NSBezierPath alloc] init];
    [bezierPath moveToPoint:NSMakePoint(drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), NSMaxY(self.bounds))];
    [bezierPath lineToPoint:NSMakePoint(drawRightArrow ? NSMaxX(self.bounds) - lineWidth*0.5 : NSMinX(self.bounds) + lineWidth*0.5, NSMidY(self.bounds))];
    [bezierPath lineToPoint:NSMakePoint(drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), NSMidY(self.bounds))];
    bezierPath.lineWidth = lineWidth;
    bezierPath.lineCapStyle = NSRoundLineCapStyle;
    bezierPath.lineJoinStyle = NSRoundLineJoinStyle;
    self.mouseDown ? self.blackColor : [[self.blackColor colorWithAlphaComponent:0.33] setStroke];
    [bezierPath stroke];
    
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    self.mouseDown = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    
    self.mouseDown = NO;
    
    [NSApp sendAction:self.action to:self.target from:self];
}

@end
