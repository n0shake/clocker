//
//  CLCustomSliderCell.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/19/15.
//
//

#import "CLCustomSliderCell.h"

@implementation CLCustomSliderCell

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
    rect.size.height = 5.0;
    
    // Bar radius
    CGFloat barRadius = 2.5;
    
    // Knob position depending on control min/max value and current control value.
    CGFloat value = ([self doubleValue]  - [self minValue]) / ([self maxValue] - [self minValue]);
    
    // Final Left Part Width
    CGFloat finalWidth = value * ([[self controlView] frame].size.width - 8);
    
    // Left Part Rect
    NSRect leftRect = rect;
    leftRect.size.width = finalWidth;
    
     NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect: rect xRadius: barRadius yRadius: barRadius];
    NSString *theme = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultTheme"];
    [theme isEqualToString:@"Black"] ? [NSColor.whiteColor setFill] :  [[NSColor colorWithCalibratedRed:67.0/255.0 green:138.0/255.0 blue:250.0/255.0 alpha:1.0] setFill];
    [bg fill];

    // Draw Right Part
    NSBezierPath* active = [NSBezierPath bezierPathWithRoundedRect: leftRect xRadius: barRadius yRadius: barRadius];
    [[NSColor colorWithCalibratedRed:67.0/255.0 green:138.0/255.0 blue:250.0/255.0 alpha:1.0] setFill];
    [theme isEqualToString:@"Black"] ? [[NSColor colorWithCalibratedRed:67.0/255.0 green:138.0/255.0 blue:250.0/255.0 alpha:1.0] setFill] : [NSColor.grayColor setFill];
    [active fill];

}

@end
