//
//  CLScaleUpButton.m
//  Clocker
//
//  Created by Abhishek Banthia on 5/9/16.
//
//

#import "CLScaleUpButton.h"
#import <pop/POP.h>

@implementation CLScaleUpButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    
    POPSpringAnimation *scale = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scale.velocity = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    scale.springBounciness = 20.f;
    
    [self.layer pop_addAnimation:scale forKey:@"scale"];
}

-(void)updateTrackingAreas
{
    if(self.trackingArea != nil) {
        [self removeTrackingArea:self.trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    self.trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                      options:opts
                                                        owner:self
                                                     userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

@end
