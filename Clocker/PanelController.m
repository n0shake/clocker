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
#import "CLRatingCellView.h"
#import "CommonStrings.h"
#import "CLTimezoneCellView.h"
#import "DateTools.h"
#import "CLTimezoneData.h"
#import "Panel.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 300
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#define BUFFER 2
#define MAX_TALL 15

#pragma mark -

#import "CLOneWindowController.h"
#import "CommonStrings.h"
#import "Reachability.h"

NSString *const CLPanelNibIdentifier = @"Panel";
NSString *const CLRatingCellViewIdentifier = @"ratingCellView";
NSString *const CLTimezoneCellViewIdentifier = @"timeZoneCell";

static PanelController *sharedPanel = nil;

@implementation PanelController

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
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
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey] isEqualToString:@"Black"]) {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
    }
    
    [self updateDefaultPreferences];
    self.mainTableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    
    
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    //Register for drag and drop
    [self.mainTableview registerForDraggedTypes: [NSArray arrayWithObject:CLDragSessionKey]];
    
    [self updatePanelColor];
    
}

/*
- (void)openAsFloatingWindow
{
    
    if (self.panelWindow)
    {
        [self.panelWindow.window makeKeyAndOrderFront:nil];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:CLShowAppInForeground];
    
    self.panelWindow = [PanelController sharedPanel];
    self.panelWindow.window.level = NSFloatingWindowLevel;
    
    self.panelWindow.window.styleMask = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask;
    self.panelWindow.window.titlebarAppearsTransparent = YES;
    self.panelWindow.window.titleVisibility = NSWindowTitleVisible;
    [self.panelWindow showWindow:nil];
    NSSize maxWindowSize;
    maxWindowSize.width = self.window.frame.size.width;
    maxWindowSize.height = self.window.frame.size.height+40;
    NSSize minWindowSize;
    minWindowSize.width = 110;
    minWindowSize.height = 50;
    
    NSSize currentSize;
    currentSize.width = self.window.frame.size.width;
    currentSize.height = self.window.frame.size.height;
    
    self.panelWindow.window.contentMaxSize = maxWindowSize;
    self.panelWindow.window.contentMinSize = minWindowSize;
    
    [self.panelWindow.window setContentSize:currentSize];
    [NSApp activateIgnoringOtherApps:YES];
    
    self.floatingWindowTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self selector:@selector(updateTime)
                                                              userInfo:nil
                                                               repeats:YES];
}

- (void)updateTime
{
    if (self.panelWindow)
    {
        [self.panelWindow.mainTableview reloadData];
    }
}*/

#pragma mark -
#pragma mark Updating Timezones
#pragma mark -

- (void) updateDefaultPreferences
{
    
    NSArray *defaultZones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    
    self.defaultPreferences = self.defaultPreferences == nil ? [[NSMutableArray alloc] initWithArray:defaultZones] : [NSMutableArray arrayWithArray:defaultZones];
    
    self.scrollViewHeight.constant = self.showReviewCell ?
    (self.defaultPreferences.count+1)*55+40 : self.defaultPreferences.count*55 + 30;
    
    if (self.defaultPreferences.count == 0) {
        self.futureSlider.hidden = YES;
        self.sliderLabel.hidden = YES;
    }
    else
    {
        self.futureSlider.hidden = NO;
        self.sliderLabel.hidden = NO;
    }
    
    //hide the label when show review cell is shown so that the Main Panel looks cleaner
    
    if (self.showReviewCell) {
        self.sliderLabel.hidden = YES;
    }
    
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
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
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
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
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
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    self.futureSliderValue = 0;
    
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];
    
    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    
    panelRect.size.height = self.showReviewCell ? (self.defaultPreferences.count+1)*55+40: self.defaultPreferences.count*55 + 30;
    
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 5;
            
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [self.mainTableview reloadData];
    
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

#pragma mark -
#pragma mark NSTableview Datasource
#pragma mark -

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (self.showReviewCell) {
        return self.defaultPreferences.count+1;
    }
    return self.defaultPreferences.count;
}



-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (self.showReviewCell && row == self.defaultPreferences.count) {
        CLRatingCellView *cellView = [self.mainTableview
                                      makeViewWithIdentifier:CLRatingCellViewIdentifier
                                      owner:self];
        return cellView;
    }
    
    CLTimezoneCellView *cell = [tableView makeViewWithIdentifier:CLTimezoneCellViewIdentifier owner:self];
    
    CLTimezoneData *dataObject = [CLTimezoneData getCustomObject:self.defaultPreferences[row]];
    
    NSTextView *customLabel = (NSTextView*)[cell.relativeDate.window
                                            fieldEditor:YES
                                            forObject:cell.relativeDate];
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (theme.length > 0 && ![theme isEqualToString:@"Default"])
    {
        [cell updateTextColorWithColor:[NSColor whiteColor] andCell:cell];
        [self.mainTableview setBackgroundColor:[NSColor blackColor]];
        self.window.alphaValue = 0.90;
        [cell.customName setDrawsBackground:YES];
        [cell.customName setBackgroundColor:[NSColor blackColor]];
        customLabel.insertionPointColor = [NSColor whiteColor];
    }
    else
    {
        
        [cell updateTextColorWithColor:[NSColor blackColor] andCell:cell];
        [cell.customName setDrawsBackground:NO];
        [self.mainTableview setBackgroundColor:[NSColor whiteColor]];
        self.window.alphaValue = 1;
        customLabel.insertionPointColor = [NSColor blackColor];
    }
    
    cell.relativeDate.stringValue = [dataObject getDateForTimeZoneWithFutureSliderValue:self.futureSliderValue andDisplayType:CLPanelDisplay];
    
    cell.time.stringValue = [dataObject getTimeForTimeZoneWithFutureSliderValue:self.futureSliderValue];
    
    cell.rowNumber = row;
    
    cell.customName.stringValue = [dataObject formatStringShouldContainCity:YES];
    
    NSNumber *displayFutureSlider = [[NSUserDefaults standardUserDefaults] objectForKey:CLDisplayFutureSliderKey];
    if ([displayFutureSlider isEqualToNumber:[NSNumber numberWithInteger:0]])
    {
        self.futureSlider.hidden = NO;
        self.sliderLabel.hidden = NO;
    }
    else
    {
        self.sliderLabel.hidden = YES;
        self.futureSlider.hidden = YES;
    }
    
    [cell setUpAutoLayoutWithCell:cell];
    
    return cell;
}

#pragma mark -
#pragma mark NSTableview Drag and Drop
#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:CLDragSessionKey] owner:self];
    [pboard setData:data forType:CLDragSessionKey];
    return YES;
}


-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([object isKindOfClass:[NSString class]])
    {
        CLTimezoneData *dataObject = self.defaultPreferences[row];
        
        if ([dataObject.formattedAddress isEqualToString:object])
        {
            return;
        }
        
        dataObject.customLabel = object;
        [self.defaultPreferences replaceObjectAtIndex:row withObject:dataObject];
        [[NSUserDefaults standardUserDefaults] setObject:self.defaultPreferences forKey:CLDefaultPreferenceKey];
        [self.mainTableview reloadData];
    }
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pBoard = [info draggingPasteboard];
    
    NSData *data = [pBoard dataForType:CLDragSessionKey];
    
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self.defaultPreferences exchangeObjectAtIndex:rowIndexes.firstIndex
                                 withObjectAtIndex:row];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.defaultPreferences
                                              forKey:CLDefaultPreferenceKey];
    
    
    [[NSApplication sharedApplication].windows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([window.windowController isMemberOfClass:[CLOneWindowController class]]) {
            CLOneWindowController *ref = (CLOneWindowController *) window.windowController;
            [ref.preferencesView refereshTimezoneTableView];
        }
        
    }];
    
    [self.mainTableview reloadData];
    
    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationEvery;
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

#pragma mark -
#pragma mark Hiding Buttons on Mouse Exit
#pragma mark -

- (void)showOptions:(BOOL)value
{
    if (self.showReviewCell) {
        self.sliderLabel.hidden = YES;
        self.panelWindow.sliderLabel.hidden = YES;
        return;
    }
    
    
    if (!self.futureSlider.isHidden) {
        self.sliderLabel.hidden = !value;
        self.panelWindow.sliderLabel.hidden = !value;
    }
    
    
    if (self.defaultPreferences.count == 0)
    {
        value = YES;
        if (!self.futureSlider.isHidden)
        {
            self.sliderLabel.hidden = YES;
        }
    }
    
    if (self.panelWindow.defaultPreferences.count == 0)
    {
        value = YES;
        
        if (!self.panelWindow.futureSlider.isHidden)
        {
            self.panelWindow.sliderLabel.hidden = YES;
        }
    }
    
    self.panelWindow.shutdownButton.hidden = !value;
    self.panelWindow.preferencesButton.hidden = !value;
    
    if (value)
    {
        self.panelWindow.window.styleMask = NSResizableWindowMask | NSClosableWindowMask | NSTitledWindowMask;
    }
    else
    {
        self.panelWindow.window.styleMask = NSBorderlessWindowMask;
    }
  
    self.shutdownButton.hidden = !value;
    self.preferencesButton.hidden = !value;
    
}

- (IBAction)sliderMoved:(id)sender
{    
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:self.futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    
    self.dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    self.dateFormatter.timeStyle = kCFDateFormatterShortStyle;
    
    NSString *relativeDate = [currentCalendar isDateInToday:newDate] ? @"Today" : @"Tomorrow";
    
    NSString *helper = [self.dateFormatter stringFromDate:newDate];
    
    NSHelpManager *helpManager = [NSHelpManager sharedHelpManager];
    
    NSPoint pointInScreen = [NSEvent mouseLocation];
    pointInScreen.y -= 5;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", relativeDate, helper]];
    [NSHelpManager setContextHelpModeActive:YES];
    [helpManager setContextHelp:attributedString forObject:self.futureSlider];
    [helpManager showContextHelpForObject:self.futureSlider locationHint:pointInScreen];
    
    [self.mainTableview reloadData];
}

- (void)removeContextHelpForSlider
{
    NSEvent *newEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                           location:self.window.mouseLocationOutsideOfEventStream
                                      modifierFlags:0
                                          timestamp:0
                                       windowNumber:self.window.windowNumber
                                            context:self.window.graphicsContext
                                        eventNumber:0
                                         clickCount:1
                                           pressure:0];
    [NSApp postEvent:newEvent atStart:NO];
    newEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
                                  location:self.window.mouseLocationOutsideOfEventStream
                             modifierFlags:0
                                 timestamp:0
                              windowNumber:self.window.windowNumber
                                   context:self.window.graphicsContext
                               eventNumber:0
                                clickCount:1
                                  pressure:0];
    
    [NSApp postEvent:newEvent atStart:NO];
}

- (void)updatePanelColor
{
    NSString *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (theme.length > 0 && ![theme isEqualToString:@"Default"])
    {
        [self.mainTableview setBackgroundColor:[NSColor blackColor]];
        self.window.alphaValue = 0.90;
    }
    else
    {
        [self.mainTableview setBackgroundColor:[NSColor whiteColor]];
        self.window.alphaValue = 1;
    }
}

@end
