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
    
    if (!self.dateFormatter)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
    }
    
    [self updateDefaultPreferences];

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
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    //Register for drag and drop
    [self.mainTableview registerForDraggedTypes: [NSArray arrayWithObject:CLDragSessionKey]];

}

#pragma mark -
#pragma mark Updating Timezones
#pragma mark -

- (void) updateDefaultPreferences
{
    NSArray *defaultZones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    
    self.defaultPreferences = self.defaultPreferences == nil ? [[NSMutableArray alloc] initWithArray:defaultZones] : [NSMutableArray arrayWithArray:defaultZones];
       
    self.scrollViewHeight.constant = self.showReviewCell ? (self.defaultPreferences.count+1)*55+40 : self.defaultPreferences.count*55 + 30;
    
    if (self.defaultPreferences.count == 0) {
        self.futureSlider.hidden = YES;
        self.sliderLabel.hidden = YES;
    }
    else
    {
        self.futureSlider.hidden = NO;
        self.sliderLabel.hidden = NO;
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
    
    NSTextView *customLabel = (NSTextView*)[cell.relativeDate.window fieldEditor:YES
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
    
    cell.relativeDate.stringValue = [self getDateForTimeZone:self.defaultPreferences[row]];
    
    cell.time.stringValue = [self getTimeForTimeZone:self.defaultPreferences[row][CLTimezoneID]];
    
    cell.rowNumber = row;
    
    cell.customName.stringValue = [self formatStringShouldContainCity:YES
                                                     withTimezoneName:self.defaultPreferences[row]];
    
    NSNumber *displaySuntimings = [[NSUserDefaults standardUserDefaults] objectForKey:CLDisplaySunTimingKey];
    if ([displaySuntimings isEqualToNumber:[NSNumber numberWithInteger:0]] && self.defaultPreferences[row][@"sunriseTime"] && self.defaultPreferences[row][@"sunsetTime"]) {
          cell.sunTime.stringValue = [self getFormattedSunriseOrSunsetTime:self.
                                      defaultPreferences[row] andSunImage:cell];
    }
    else
    {
        cell.sunImage.image = nil;
        cell.sunTime.stringValue = CLEmptyString;
    }
    
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
#pragma mark Datasource formatting
#pragma mark -

- (NSString *)formatStringShouldContainCity:(BOOL)value withTimezoneName:(NSMutableDictionary *)timeZoneDictionary
{
    if (timeZoneDictionary[CLCustomLabel]) {
        NSString *customLabel = timeZoneDictionary[CLCustomLabel];
        if (customLabel.length > 0)
        {
            return customLabel;
        }
    }

    if ([timeZoneDictionary[CLTimezoneName] length] > 0)
    {
        return timeZoneDictionary[CLTimezoneName];
    }
    else if (timeZoneDictionary[CLTimezoneID])
    {
        NSString *timezoneID = timeZoneDictionary[CLTimezoneID];
        
        NSRange range = [timezoneID rangeOfString:@"/"];
        if (range.location != NSNotFound)
        {
            timezoneID = [timezoneID substringWithRange:NSMakeRange(range.location+1, timezoneID.length-1 - range.location)];
        }
        return timezoneID;
    }
    else
    {
        return @"Error";
    }

}

- (NSString *)getFormattedSunriseOrSunsetTime:(NSMutableDictionary *)originalTime
                                  andSunImage:(CLTimezoneCellView *)cell
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSDate *sunTime = [formatter dateFromString:originalTime[@"sunriseTime"]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:originalTime[CLTimezoneID]];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
     dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *newDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDateFormatter *dateConversion = [[NSDateFormatter alloc] init];
      dateConversion.timeZone = [NSTimeZone timeZoneWithName:originalTime[CLTimezoneID]];
    dateConversion.dateStyle = kCFDateFormatterShortStyle;
    dateConversion.timeStyle = kCFDateFormatterShortStyle;
    dateConversion.dateFormat = @"yyyy-MM-dd HH:mm";
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if ([sunTime laterDate:[dateConversion dateFromString:newDate]] == sunTime)
    {
        cell.sunImage.image = theme.length > 0 && [theme isEqualToString:@"Default"] ?
         [NSImage imageNamed:@"Sunrise"] : [NSImage imageNamed:@"White Sunrise"];
       return [originalTime[@"sunriseTime"] substringFromIndex:11];
    }
    else
    {
        cell.sunImage.image = theme.length > 0 && [theme isEqualToString:@"Default"] ?
         [NSImage imageNamed:@"Sunset"] : [NSImage imageNamed:@"White Sunset"];
        return [originalTime[@"sunsetTime"] substringFromIndex:11];
    }
}

- (NSString *)getTimeForTimeZone:(NSString *)timezoneID
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitHour
                                                  value:self.futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    
    NSNumber *is24HourFormatSelected = [[NSUserDefaults standardUserDefaults] objectForKey:CL24hourFormatSelectedKey];
    
    is24HourFormatSelected.boolValue ? [dateFormatter setDateFormat:@"HH:mm"] : [dateFormatter setDateFormat:@"hh:mm a"];
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:timezoneID];
    //In the format 22:10
    
    return [dateFormatter stringFromDate:newDate];
}

- (NSString *)getLocalCurrentDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    return [NSDateFormatter localizedStringFromDate:[NSDate date]
                                          dateStyle:NSDateFormatterShortStyle
                                          timeStyle:NSDateFormatterNoStyle];

}

- (NSString *)compareSystemDate:(NSString *)systemDate toTimezoneDate:(NSString *)date andDictionary:(NSMutableDictionary *)dictionary
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy"
                                                           options:0
                                                            locale:[NSLocale currentLocale]];
    
    NSDate *localDate = [formatter dateFromString:systemDate];
    NSDate *timezoneDate = [formatter dateFromString:date];
    
    if (localDate == nil || timezoneDate == nil) {
        [CrashlyticsKit setUserEmail:systemDate];
        [CrashlyticsKit setUserIdentifier:date];
        return @"Today";
    }
    
    // Specify which units we would like to use
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:localDate];
    
    if ([dictionary[@"nextUpdate"] isKindOfClass:[NSString class]])
    {

        NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:units fromDate:timezoneDate];
        comps.day = comps.day + 1;
        NSDate *tomorrowMidnight = [[NSCalendar currentCalendar] dateFromComponents:comps];
        
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] initWithDictionary:dictionary copyItems:YES];
        [newDict setObject:tomorrowMidnight forKey:@"nextUpdate"];

        
        [self.defaultPreferences replaceObjectAtIndex:[self.defaultPreferences indexOfObject:dictionary] withObject:newDict];
        [[NSUserDefaults standardUserDefaults] setObject:self.defaultPreferences forKey:CLDefaultPreferenceKey];
    }
    else if ([dictionary[@"nextUpdate"] isKindOfClass:[NSDate class]] &&
             [dictionary[@"nextUpdate"] isEarlierThanOrEqualTo:timezoneDate])
    {
            [self getTimeZoneForLatitude:dictionary[@"latitude"]
                            andLongitude:dictionary[@"longitude"]
                           andDictionary:dictionary];
    }
    
    NSInteger daysApart = [timezoneDate daysFrom:localDate];
    
    if (daysApart == 0) {
        return @"Today";
    }
    else if (daysApart == -1)
    {
        return @"Yesterday";
    }
    else if (daysApart == 1)
    {
        return @"Tomorrow";
    }
    else
    {
        return [self getWeekdayFromInteger:weekday+2];
    }
}

- (NSString *)getDateForTimeZone:(NSMutableDictionary *)dictionary
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitHour
                                                  value:self.futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeStyle = kCFDateFormatterNoStyle;
    
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:dictionary[CLTimezoneID]];
    
    NSNumber *relativeDayPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLRelativeDateKey];
    if (relativeDayPreference.integerValue == 0) {
         return [self compareSystemDate:[self getLocalCurrentDate]
                         toTimezoneDate:[dateFormatter stringFromDate:newDate] andDictionary:dictionary] ;;
    }
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MM/dd/yyyy" options:0 locale:[NSLocale currentLocale]];
        
        NSDate *convertedDate = [formatter dateFromString:[dateFormatter stringFromDate:newDate]];

        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:convertedDate];
        return [self getWeekdayFromInteger:weekday];
    }
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
        NSMutableDictionary *timezoneDictionary = self.defaultPreferences[row];
        
        if ([self.defaultPreferences[row][CLTimezoneName] isEqualToString:object])
        {
            return;
        }
        
        NSMutableDictionary *mutableTimeZoneDict = [timezoneDictionary mutableCopy];
        [mutableTimeZoneDict setValue:object forKey:CLCustomLabel];
        [self.defaultPreferences replaceObjectAtIndex:row withObject:mutableTimeZoneDict];
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
    
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        if ([window.windowController isMemberOfClass:[CLOneWindowController class]]) {
            CLOneWindowController *ref = (CLOneWindowController *) window.windowController;
            [ref.preferencesView refereshTimezoneTableView];
        }
    }
    
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
    if (!self.futureSlider.isHidden) {
           self.sliderLabel.hidden = !value;
    }
 
    
    if (self.defaultPreferences.count == 0)
    {
        value = YES;
        if (!self.futureSlider.isHidden)
        {
            self.sliderLabel.hidden = YES;
        }
        
    }
   
    self.shutdownButton.hidden = !value;
    self.preferencesButton.hidden = !value;

}

- (IBAction)sliderMoved:(id)sender
{    
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitHour
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

- (NSString *)getWeekdayFromInteger:(NSInteger)weekdayInteger
{
    if (weekdayInteger > 7) {
        weekdayInteger = weekdayInteger - 7;
    }
    
    switch (weekdayInteger) {
        case 1:
            return @"Sunday";
            break;
            
        case 2:
            return @"Monday";
            break;
            
        case 3:
            return @"Tuesday";
            break;
            
        case 4:
            return @"Wednesday";
            break;
            
        case 5:
            return @"Thursday";
            break;
            
        case 6:
            return @"Friday";
            break;
            
        case 7:
            return @"Saturday";
            break;
            
        default:
            return @"Error";
            break;
    }
}

- (void)getTimeZoneForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude andDictionary:(NSMutableDictionary *)dictionary
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable)
    {
        //Could not fetch data
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://api.geonames.org/timezoneJSON?lat=%@&lng=%@&username=abhishaker17", latitude, longitude];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSError *error = nil;
    
    if (!error) {
        
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (httpResp.statusCode == 200)
                {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSDictionary* json = [NSJSONSerialization
                                              JSONObjectWithData:data
                                              options:kNilOptions
                                              error:nil];
                        
                        if (json.count == 0) {
                           //No results found
                            return;
                        }
                        
                        if ([json[@"status"][@"message"] isEqualToString:@"the hourly limit of 2000 credits for abhishaker17 has been exceeded. Please throttle your requests or use the commercial service."])
                        {
                            return;
                        }
                        
                        
                        
                        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary copyItems:YES];
                        
                        if (json[@"sunrise"] && json[@"sunset"]) {
                            [newDictionary setObject:json[@"sunrise"] forKey:@"sunriseTime"];
                            [newDictionary setObject:json[@"sunset"] forKey:@"sunsetTime"];
                        }
                     
                        NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
                        NSDateComponents *comps = [[NSCalendar currentCalendar] components:units fromDate:newDictionary[@"nextUpdate"]];
                        comps.day = comps.day + 1;
                        NSDate *tomorrowMidnight = [[NSCalendar currentCalendar] dateFromComponents:comps];

                        [newDictionary setObject:tomorrowMidnight forKey:@"nextUpdate"];
                        
                        
                        NSArray *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
                        
                        if (defaultPreference == nil)
                        {
                            defaultPreference = [[NSMutableArray alloc] init];
                        }
                        
                        NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:defaultPreference];
                        
                        for (NSMutableDictionary *timeDictionary in self.defaultPreferences) {
                            if ([dictionary[CLPlaceIdentifier] isEqualToString:timeDictionary[CLPlaceIdentifier]]) {
                                [newArray replaceObjectAtIndex:[self.defaultPreferences indexOfObject:timeDictionary] withObject:newDictionary];
                            }
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:CLDefaultPreferenceKey];
                        
                        [self.mainTableview reloadData];
                        
                    });
                }
            }
            else
            {
                //error
            }
            
        }];
        
        [dataTask resume];
        
    }
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
