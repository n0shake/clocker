//
//  CLUnderlinedButton.m
//  Clocker
//
//  Created by Abhishek Banthia on 1/14/17.
//
//

#import "CLUnderlinedButton.h"

@implementation CLUnderlinedButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)resetCursorRects
{
    if (self.cursor) {
        [self addCursorRect:[self bounds] cursor: self.cursor];
    } else {
        [super resetCursorRects];
    }
}

@end
