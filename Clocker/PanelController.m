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


#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import <Crashlytics/Crashlytics.h>
#import "CommonStrings.h"
#import "DateTools.h"
#import "Panel.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 300
//#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#define BUFFER 2
#define MAX_TALL 15

#pragma mark -

#import "CLOneWindowController.h"
#import "CommonStrings.h"
#import "Reachability.h"

NSString *const CLPanelNibIdentifier = @"Panel";

static PanelController *sharedPanel = nil;

@implementation PanelController

#pragma mark -

- (instancetype)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:CLPanelNibIdentifier];
    if (self != nil)
    {
        _delegate = delegate;
        self.window.backgroundColor = [NSColor whiteColor];
    }
    return self;
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.futureSlider.continuous = YES;
    
    if (!self.dateFormatter)
    {
        self.dateFormatter = [NSDateFormatter new];
    }
    
    self.mainTableview.delegate = self;
    
    NSPanel *panel = (id)self.window;
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    panel.backgroundColor = [NSColor clearColor];
    
    //Register for drag and drop
    [self.mainTableview registerForDraggedTypes: @[CLDragSessionKey]];
    
    [super updatePanelColor];
    
    [super updateDefaultPreferences];

}


#pragma mark -
#pragma mark Updating Timezones
#pragma mark -

- (void) updateDefaultPreferences
{
    [super updateDefaultPreferences];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        _hasActivePanel ? [self openPanel] : [self closePanel];
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    if (self.tableViewTimer)
    {
        [self.tableViewTimer.timer invalidate];
        self.tableViewTimer = nil;
    }
    
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if (self.window.visible)
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = self.window;
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = panel.frame;
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSEnumerator *screenEnum = [[NSScreen screens] objectEnumerator];
    NSScreen *screen;
    while ((screen = [screenEnum nextObject]) && !NSMouseInRect(mouseLoc,
                                                                [screen frame], NO));
    
    
    NSRect screenRect = screen.frame;
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [NSStatusBar systemStatusBar].thickness);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    [Answers logCustomEventWithName:@"openedPanel" customAttributes:@{}];
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSEnumerator *screenEnum = [[NSScreen screens] objectEnumerator];
    NSScreen *screen;
    while ((screen = [screenEnum nextObject]) && !NSMouseInRect(mouseLoc,
                                                                [screen frame], NO));
    
    self.futureSliderValue = 0;
    self.timezoneDataSource.futureSliderValue = 0;
    
    self.reviewView.hidden = !self.showReviewCell;
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    self.reviewView.layer.backgroundColor = (theme.integerValue == 0) ? [NSColor whiteColor].CGColor :  [NSColor blackColor].CGColor;
    
    NSWindow *panel = self.window;
    
    NSRect screenRect = screen.frame;
    NSRect statusRect = [self statusRectForWindow:panel];
    
    NSRect panelRect = panel.frame;
    panelRect.size.width = panel.frame.size.width;
    
    panelRect.size.height = self.window.frame.size.height;
    
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    panel.alphaValue = 0;
    [panel setFrame:panelRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = NSApp.currentEvent;
    if (currentEvent.type == NSLeftMouseDown)
    {
        NSUInteger clearFlags = (currentEvent.modifierFlags & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 5;
            
        }
    }
    
    [NSAnimationContext beginGrouping];
    [NSAnimationContext currentContext].duration = openDuration;
    [[panel animator] setFrame:panelRect display:YES];
    [panel animator].alphaValue = 1;
    [NSAnimationContext endGrouping];
    
    NSNumber *showSeconds = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowSecondsInMenubar];
    
    [showSeconds isEqualToNumber:@(1)] ? [self.mainTableview reloadData] : [self startWindowTimer];
    
}

- (void)startWindowTimer
{
    if (!self.tableViewTimer)
    {
        self.tableViewTimer = [CLPausableTimer timerWithTimeInterval:1.0
                                                                   target:self
                                                                 selector:@selector(updateTime) userInfo:nil
                                                                  repeats:YES];
        [self.tableViewTimer start]; //Explicitly start the timer
    }
}

- (void)updateTime
{
    [self.mainTableview reloadData];
}


- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [self.window animator].alphaValue = 0;
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

#pragma mark -
#pragma mark Preferences Target-Action
#pragma mark -

- (IBAction)openPreferences:(id)sender
{
    self.oneWindow = [CLOneWindowController sharedWindow];
    [self.oneWindow showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    
}

+ (instancetype)getPanelControllerInstance
{
    __block PanelController *panelController;
    
    [[NSApplication sharedApplication].windows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([window.windowController isMemberOfClass:[PanelController class]])
        {
            panelController = window.windowController;
        }
    }];
    
    return panelController;
}

@end
