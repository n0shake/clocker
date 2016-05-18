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

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSButtonCell *cell = [self cell];
    
    cell.backgroundColor = [NSColor clearColor];
    

    // Drawing code here.
}

- (void)awakeFromNib
{
    if (self.textColor)
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setAlignment:NSCenterTextAlignment];
        NSDictionary *attrsDictionary  = [NSDictionary dictionaryWithObjectsAndKeys:
                                          self.textColor, NSForegroundColorAttributeName,
                                          self.font, NSFontAttributeName,
                                          style, NSParagraphStyleAttributeName, nil];
        NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:self.title attributes:attrsDictionary];
        [self setAttributedTitle:attrString];
    }
    
    [self addScaleAnimation];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    
    [self addScaleAnimation];

}

- (void) addScaleAnimation
{
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
