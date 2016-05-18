//
//  CLScaleUpButton.h
//  Clocker
//
//  Created by Abhishek Banthia on 5/9/16.
//
//

#import <Cocoa/Cocoa.h>

@interface CLScaleUpButton : NSButton

@property (strong, nonatomic) NSTrackingArea *trackingArea;
@property (nonatomic, strong) IBInspectable NSColor *textColor;

@end
