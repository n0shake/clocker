//
//  CLPreferencesViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import "CLPreferencesViewController.h"
#import "Panel.h"
#import "PanelController.h"
#import "ApplicationDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "CommonStrings.h"

NSString *const CLSearchPredicateKey = @"SELF CONTAINS[cd]%@";
NSString *const CLPreferencesViewNibIdentifier = @"PreferencesWindow";
NSString *const CLPreferencesTimezoneNameIdentifier = @"timezoneName";
NSString *const CLPreferencesAbbreviationIdentifier = @"abbreviation";
NSString *const CLPreferencesCustomLabelIdentifier = @"label";
NSString *const CLPreferencesAvailableTimezoneIdentifier = @"availableTimezones";

@interface CLPreferencesViewController ()

@property (weak) IBOutlet NSTableView *timezoneTableView;
@property (strong) IBOutlet Panel *timezonePanel;

@property (weak) IBOutlet NSTableView *availableTimezoneTableView;
@property (weak) IBOutlet NSSearchField *searchField;

@property (weak) IBOutlet NSButton *is24HourFormatSelected;
@property (weak) IBOutlet NSTextField *messageLabel;

@end

@implementation CLPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refereshTimezoneTableView) name:CLCustomLabelChangedNotification object:nil];

    
    [self refereshTimezoneTableView];
    
    if (!self.timeZoneArray)
    {
        self.timeZoneArray = [[NSMutableArray alloc] initWithArray:[NSTimeZone knownTimeZoneNames]];
        
        self.filteredArray = [[NSArray alloc] init];
    }
    
    self.messageLabel.stringValue = CLEmptyString;

    [self.availableTimezoneTableView reloadData];
    
    //Register for drag and drop
    [self.timezoneTableView registerForDraggedTypes: [NSArray arrayWithObject: CLDragSessionKey]];

    // Do view setup here.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CLCustomLabelChangedNotification object:nil];
}


-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.timezoneTableView) {
        return self.selectedTimeZones.count;
    }
    else
    {
        if (self.searchField.stringValue.length > 0) {
            return self.filteredArray.count;
        }
        return self.timeZoneArray.count;
    }
    
    return 0;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:CLPreferencesTimezoneNameIdentifier])
    {
        return self.selectedTimeZones[row][CLTimezoneName];
    }
    else if([[tableColumn identifier] isEqualToString:CLPreferencesAvailableTimezoneIdentifier])
    {
        if (self.searchField.stringValue.length > 0)
        {
            return self.filteredArray[row];
        }
        
        return self.timeZoneArray[row];
    }
    else if([[tableColumn identifier] isEqualToString:CLPreferencesCustomLabelIdentifier])
    {
        return self.selectedTimeZones[row][CLCustomLabel];
    }
    if ([tableColumn.identifier isEqualToString:CLPreferencesAbbreviationIdentifier])
    {
        if (self.searchField.stringValue.length > 0)
        {
            return [NSTimeZone timeZoneWithName:self.filteredArray[row]].abbreviation;
        }
        
        return [NSTimeZone timeZoneWithName:self.timeZoneArray[row]].abbreviation;
    }
    
    return nil;
    
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([object isKindOfClass:[NSString class]])
    {
        
        NSString *originalValue = (NSString *)object;
        NSString *customLabelValue = [originalValue stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];
        
        NSDictionary *timezoneDictionary = self.selectedTimeZones[row];
        NSDictionary *mutableTimeZoneDict = [timezoneDictionary mutableCopy];
        customLabelValue.length > 0 ? [mutableTimeZoneDict setValue:customLabelValue forKey:CLCustomLabel] : [mutableTimeZoneDict setValue:CLEmptyString forKey:CLCustomLabel];
        [self.selectedTimeZones replaceObjectAtIndex:row withObject:mutableTimeZoneDict];
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedTimeZones forKey:CLDefaultPreferenceKey];
        
        [self refreshMainTableview];
    }
}

- (IBAction)addTimeZone:(id)sender
{
    [self.view.window beginSheet:self.timezonePanel completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (IBAction)addToFavorites:(id)sender
{
    if (self.availableTimezoneTableView.selectedRow == -1)
    {
        self.messageLabel.stringValue = @"Please select a timezone!";
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
        return;
    }
    
    NSString *selectedTimezone;
    
    if (self.selectedTimeZones.count > 10)
    {
        self.messageLabel.stringValue = @"Maximum 10 timezones allowed!";
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
        return;
    }
    
    for (NSDictionary *timezoneDictionary in self.selectedTimeZones)
    {
        NSString *name = timezoneDictionary[CLTimezoneName];
        
        if (self.searchField.stringValue.length > 0) {
            if ([name isEqualToString:self.filteredArray[self.availableTimezoneTableView.selectedRow]])
            {
                self.messageLabel.stringValue = @"Timezone has already been selected!";
                [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
                return;
            }
        }
        else if ([name isEqualToString:self.timeZoneArray[self.availableTimezoneTableView.selectedRow]])
        {
            self.messageLabel.stringValue = @"Timezone has already been selected!";
            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
            return;
        }
    }
    
    
    selectedTimezone = self.searchField.stringValue.length > 0 ?
    self.filteredArray[self.availableTimezoneTableView.selectedRow] :
    self.timeZoneArray[self.availableTimezoneTableView.selectedRow];
    
    NSDictionary *newTimezoneToAdd = @{CLTimezoneName : selectedTimezone,
                                       CLCustomLabel : CLEmptyString};
    
    [self.selectedTimeZones addObject:newTimezoneToAdd];
    
    NSArray *defaultTimeZones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    NSMutableArray *newDefaults;
    
    if (defaultTimeZones == nil)
    {
        defaultTimeZones = [[NSMutableArray alloc] init];
    }
    
    newDefaults = [[NSMutableArray alloc] initWithArray:defaultTimeZones];
    
    [newDefaults addObject:newTimezoneToAdd];
    
    [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:CLDefaultPreferenceKey];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
    
    [self.timezonePanel close];
}

- (void)clearLabel
{
    self.messageLabel.stringValue = CLEmptyString;
}

- (IBAction)closePanel:(id)sender
{
    [self.timezonePanel close];
}

- (IBAction)removeFromFavourites:(id)sender
{
    
    NSMutableArray *itemsToRemove = [NSMutableArray array];
    
    if (self.timezoneTableView.selectedRow == -1)
    {
        return;
    }
    
    [self.timezoneTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        
        [itemsToRemove addObject:self.selectedTimeZones[idx]];
        
    }];
    
    [self.selectedTimeZones removeObjectsInArray:itemsToRemove];
    
    NSMutableArray *newDefaults = [[NSMutableArray alloc] initWithArray:self.selectedTimeZones];
    
    [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:CLDefaultPreferenceKey];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
}

-(void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    if (theEvent.keyCode == 53) {
        [self.timezonePanel close];
    }
    
}

-(void)keyUp:(NSEvent *)theEvent
{
    if (theEvent.keyCode == 53) {
        [self.timezonePanel close];
    }
}

- (IBAction)filterArray:(id)sender
{
    
    if (self.searchField.stringValue.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:CLSearchPredicateKey, self.searchField.stringValue];
        
        self.filteredArray = [self.timeZoneArray filteredArrayUsingPredicate:predicate];
    }
    
    [self.availableTimezoneTableView reloadData];
}
- (IBAction)timeFormatSelectionChanged:(id)sender {
    
    NSButton *is24HourFormatSelected = (NSButton *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:is24HourFormatSelected.state] forKey:CL24hourFormatSelectedKey];
    
    [self refreshMainTableview];
}

- (void)refereshTimezoneTableView
{
    NSMutableArray *defaultTimeZones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    self.selectedTimeZones = [[NSMutableArray alloc] initWithArray:defaultTimeZones];
    [self.timezoneTableView reloadData];
}

- (void)refreshMainTableview
{
    ApplicationDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    
    PanelController *panelController = appDelegate.panelController;
    
    [panelController updateDefaultPreferences];
    
    [panelController.mainTableview reloadData];
    
}

#pragma mark Reordering

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
    [pboard declareTypes:[NSArray arrayWithObject:CLDragSessionKey] owner:self];
    
    [pboard setData:data forType:CLDragSessionKey];
    
    return YES;
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    if (row == self.selectedTimeZones.count) {
        row--;
    }
    
    NSPasteboard *pBoard = [info draggingPasteboard];
    
    NSData *data = [pBoard dataForType:CLDragSessionKey];
    
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self.selectedTimeZones exchangeObjectAtIndex:rowIndexes.firstIndex withObjectAtIndex:row];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedTimeZones forKey:CLDefaultPreferenceKey];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
    
    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationEvery;
}


- (BOOL)launchOnLogin
{
    LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
    NSArray* loginItems = CFBridgingRelease(snapshotRef);
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
            if ([itemURL isEqual:bundleURL]) {
                return YES;
            }
        }
    }
    return NO;
}

-(void)setLaunchOnLogin:(BOOL)launchOnLogin
{
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (launchOnLogin) {
        NSDictionary *properties;
        properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.loginitem.HideOnLaunch"];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsListRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)bundleURL, (__bridge CFDictionaryRef)properties,NULL);
        if (itemRef) {
            CFRelease(itemRef);
        }
    } else {
        LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
        NSArray* loginItems = CFBridgingRelease(snapshotRef);
        
        for (id item in loginItems) {
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
            CFURLRef itemURLRef;
            if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
                NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
                if ([itemURL isEqual:bundleURL]) {
                    LSSharedFileListItemRemove(loginItemsListRef, itemRef);
                }
            }
        }
    }
}

@end
