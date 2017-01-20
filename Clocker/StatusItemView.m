//  Created by Abhishek Banthia on 11/4/15.
//  Copyright (c) 2015 Abhishek Banthia All rights reserved.
//

// Copyright (c) 2015, Abhishek Banthia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "StatusItemView.h"
#import "CommonStrings.h"
#import "CLTimezoneData.h"
#import "DateTools.h"
#import "CLTimezoneDataOperations.h"

@implementation StatusItemView

@synthesize statusItem = _statusItem;
@synthesize image = _image;
@synthesize alternateImage = _alternateImage;
@synthesize isHighlighted = _isHighlighted;
@synthesize action = _action;
@synthesize target = _target;

#pragma mark -

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem
{
    CGFloat itemWidth = statusItem.length;
    CGFloat itemHeight = [NSStatusBar systemStatusBar].thickness;
    NSRect itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
    
    self = [super initWithFrame:itemRect];
    
    if (self != nil) {
        _statusItem = statusItem;
        _statusItem.view = self;
    }
    return self;
}


#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 22)];
    textField.bordered = NO;
    textField.alignment = NSTextAlignmentCenter;
    
    NSData *dataObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"favouriteTimezone"];
    
    if (dataObject)
    {
        CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:dataObject];
        
        CLTimezoneDataOperations *operationObject = [[CLTimezoneDataOperations alloc] initWithTimezoneData:timezoneObject];
        
        textField.stringValue = [operationObject getMenuTitle];
        textField.font = [NSFont monospacedDigitSystemFontOfSize:14.0 weight:0];
        
        // Set up dark mode for icon
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"]  isEqualToString:@"Dark"])
        {
            //Fix for Tammy Jackson's feedback
            textField.backgroundColor = [NSColor clearColor];
            textField.textColor = [NSColor whiteColor];
            self.image = [self imageWithSubviewsWithTextField:textField];
        }
        else
        {
            textField.textColor = [NSColor blackColor];
            self.image = [self imageWithSubviewsWithTextField:textField];
        }
        
        [textField sizeToFit];
        
        NSDisableScreenUpdates();
        (self.statusItem).length = textField.frame.size.width+10;
        NSEnableScreenUpdates();
        
        CGRect newRect = CGRectMake(dirtyRect.origin.x, dirtyRect.origin.y, textField.frame.size.width+5, dirtyRect.size.height);
        
        [self.statusItem drawStatusBarBackgroundInRect:newRect withHighlight:NO];
    }
    else
    {
      self.image = [NSImage imageNamed:@"MenuIcon"];
      self.statusItem.length = 24;
      [self.statusItem drawStatusBarBackgroundInRect:CGRectMake(0, 0, self.image.size.width, self.image.size.height) withHighlight:NO];
    }
    
    
    NSImage *icon = self.image;
    NSSize iconSize = icon.size;
    NSRect bounds = self.bounds;
    CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    NSPoint iconPoint = NSMakePoint(iconX, iconY);

	[icon drawAtPoint:iconPoint fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];
}


- (NSImage *)imageWithSubviewsWithTextField:(NSTextField *)textField
{
    NSSize mySize = textField.bounds.size;
    NSSize imgSize = NSMakeSize( mySize.width, mySize.height+1.2);
    
    NSBitmapImageRep *bir = [textField bitmapImageRepForCachingDisplayInRect:textField.bounds];
    bir.size = imgSize;
    [textField cacheDisplayInRect:textField.bounds toBitmapImageRep:bir];
    
    NSImage* image = [[NSImage alloc]initWithSize:imgSize];
    [image addRepresentation:bir];
    return image;
    
}


#pragma mark -
#pragma mark Mouse tracking

- (void)mouseDown:(NSEvent *)theEvent
{
    [NSApp sendAction:self.action to:self.target from:self];
}

#pragma mark -

- (NSRect)globalRect
{
    NSRect frame = self.frame;
    return [self.window convertRectToScreen:frame];
}
@end
