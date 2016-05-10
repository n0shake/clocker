//
//  CLFloatingWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 4/2/16.
//
//

#import "CLFloatingWindowController.h"
#import "CLRatingCellView.h"
#import "CLTimezoneData.h"
#import "CommonStrings.h"
#import "CLOneWindowController.h"

@interface CLFloatingWindowController ()

@end

static CLFloatingWindowController *sharedFloatingWindow = nil;
NSString *const CLRatingCellIdentifier = @"ratingCellView";
NSString *const CLTimezoneCellIdentifier = @"timeZoneCell";

@implementation CLFloatingWindowController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.futureSlider.continuous = YES;
    
    if (!self.dateFormatter)
    {
        self.dateFormatter = [NSDateFormatter new];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey] isKindOfClass:[NSString class]]){
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLThemeKey];
    }
    
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
  
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
        self.window.backgroundColor = [NSColor blackColor];
        [panel setBackgroundColor:[NSColor blackColor]];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
        self.window.backgroundColor = [NSColor whiteColor];
        [panel setBackgroundColor:[NSColor whiteColor]];
    }
    
    [self updateDefaultPreferences];
    
    //Register for drag and drop
    [self.mainTableview registerForDraggedTypes: [NSArray arrayWithObject:CLDragSessionKey]];
    
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;

    
       
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedFloatingWindow
{
    if (sharedFloatingWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedFloatingWindow = [[self alloc] initWithWindowNibName:@"CLFloatingWindow"];
            
        });
    }
    return sharedFloatingWindow;
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
                                      makeViewWithIdentifier:CLRatingCellIdentifier
                                      owner:self];
        return cellView;
    }
    
    CLTimezoneCellView *cell = [tableView makeViewWithIdentifier:CLTimezoneCellIdentifier owner:self];
    
    CLTimezoneData *dataObject = [CLTimezoneData getCustomObject:self.defaultPreferences[row]];
    
    cell.sunriseSetTime.stringValue = [dataObject getFormattedSunriseOrSunsetTime];
    
    NSTextView *customLabel = (NSTextView*)[cell.relativeDate.window
                                            fieldEditor:YES
                                            forObject:cell.relativeDate];
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (theme.integerValue == 1)
    {
        [cell updateTextColorWithColor:[NSColor whiteColor] andCell:cell];
        [self.mainTableview setBackgroundColor:[NSColor blackColor]];
        self.window.alphaValue = 0.90;
        [cell.customName setDrawsBackground:YES];
        [cell.customName setBackgroundColor:[NSColor blackColor]];
        customLabel.insertionPointColor = [NSColor whiteColor];
        cell.sunriseSetImage.image = dataObject.sunriseOrSunset ?
        [NSImage imageNamed:@"White Sunrise"] : [NSImage imageNamed:@"White Sunset"];
        cell.sunriseSetImage.image = dataObject.sunriseOrSunset ?
        [NSImage imageNamed:@"Sunrise"] : [NSImage imageNamed:@"Sunset"];
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
    
    self.futureSlider.hidden = [displayFutureSlider isEqualToNumber:[NSNumber numberWithInteger:1]] ? YES : NO;
    
    NSNumber *displaySunriseSunsetTime = [[NSUserDefaults standardUserDefaults] objectForKey:CLSunriseSunsetTime];
    
    cell.sunriseSetTime.hidden = [displaySunriseSunsetTime isEqualToNumber:@(1)] ? YES : NO;
    
    cell.sunriseSetImage.hidden = [displaySunriseSunsetTime isEqualToNumber:@(1)] ? YES : NO;
    
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
    
    if (row == self.defaultPreferences.count)
    {
        row -= 1;
    }
    
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

- (void) updateDefaultPreferences
{
    [super updateDefaultPreferences];
    
    NSRect frame = [self.window frame];
    frame.size = NSMakeSize(self.window.frame.size.width, self.scrollViewHeight.constant+10);
    [self.window setFrame: frame display: YES animate:YES];
    
    [self.window setContentMaxSize:NSMakeSize(self.window.frame.size.width+50, self.scrollViewHeight.constant+100)];
    
    [self updateTime];
}

- (void)updateTime
{
    [self.mainTableview reloadData];
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

-(void)windowWillClose:(NSNotification *)notification
{
    self.futureSliderValue = 0;
    
    if (self.floatingWindowTimer)
    {
        [self.floatingWindowTimer.timer invalidate];
        self.floatingWindowTimer = nil;
    }
}

- (void)startWindowTimer
{
    if (!self.floatingWindowTimer)
    {
        self.floatingWindowTimer = [CLPausableTimer timerWithTimeInterval:2.0
                                                                    target:self
                                                                  selector:@selector(updateTime) userInfo:nil
                                                                   repeats:YES];
        [self.floatingWindowTimer start]; //Explicitly start the timer
    }
}

- (void)updatePanelColor
{
    [super updatePanelColor];
    
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
        self.window.backgroundColor = [NSColor blackColor];
        [panel setBackgroundColor:[NSColor blackColor]];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
        self.window.backgroundColor = [NSColor whiteColor];
        [panel setBackgroundColor:[NSColor whiteColor]];
    }

}


@end
