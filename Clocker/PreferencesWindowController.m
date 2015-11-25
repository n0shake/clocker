//
//  PreferencesWindowController.m
//  Clocker
//
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


#import "PreferencesWindowController.h"
#import "Panel.h"
#import "PanelController.h"
#import "ApplicationDelegate.h"

@interface PreferencesWindowController ()

@property (weak) IBOutlet NSTableView *timezoneTableView;
@property (strong) IBOutlet Panel *timezonePanel;

@property (weak) IBOutlet NSTableView *availableTimezoneTableView;
@property (weak) IBOutlet NSSearchField *searchField;

@property (weak) IBOutlet NSButton *is24HourFormatSelected;
@property (weak) IBOutlet NSTextField *messageLabel;
@property (weak) IBOutlet NSTextField *openSourceMessage;

@end

static PreferencesWindowController *sharedPreferences = nil;

@implementation PreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.openSourceMessage setAllowsEditingTextAttributes: YES];
    [self.openSourceMessage setSelectable:YES];
    NSString *credits = @"Clocker v1.0 is open source. You can find the source code <a href=\"https://github.com/Abhishaker17/Clocker\">here!</a>";
    [self.openSourceMessage setAttributedStringValue:[self stringFromHTML:credits withFont:[self.openSourceMessage font]]];
    
    
     NSMutableArray *defaultTimeZones = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPreferences"];
    
    if (!self.timeZoneArray || !self.selectedTimeZones)
    {
        self.timeZoneArray = [[NSMutableArray alloc] initWithArray:[NSTimeZone knownTimeZoneNames]];
        self.selectedTimeZones = [[NSMutableArray alloc] initWithArray:defaultTimeZones];
        self.filteredArray = [[NSArray alloc] init];
    }
    
    self.messageLabel.stringValue = @"";
    
    [self.timezoneTableView reloadData];
    [self.availableTimezoneTableView reloadData];
    
    //Register for drag and drop
    [self.timezoneTableView registerForDraggedTypes: [NSArray arrayWithObject: @"public.text"]];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(NSAttributedString *)stringFromHTML:(NSString *)html withFont:(NSFont *)font
{
    html = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%dpx;\">%@</span>", [font fontName], (int)[font pointSize], html];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
    return string;
}

-(id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] initWithWindowNibName:@"PreferencesWindow"];
    
    if (copy)
    {
         self.timeZoneArray = [[NSMutableArray alloc] initWithArray:[NSTimeZone knownTimeZoneNames]];
    }
    
    return copy;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

+ (instancetype)sharedPreferences
{
    if (sharedPreferences == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedPreferences = [[self alloc] initWithWindowNibName:@"PreferencesWindow"];
           
        });
        
    }
    
    return sharedPreferences;
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
    if ([[tableColumn identifier] isEqualToString:@"timezoneName"])
    {
        return self.selectedTimeZones[row];
    }
    else if([[tableColumn identifier] isEqualToString:@"availableTimezones"])
    {
        if (self.searchField.stringValue.length > 0)
        {
            return self.filteredArray[row];
        }
        
        return self.timeZoneArray[row];;
    }
    if ([tableColumn.identifier isEqualToString:@"abbreviation"])
    {
        if (self.searchField.stringValue.length > 0)
        {
            return [NSTimeZone timeZoneWithName:self.filteredArray[row]].abbreviation;
        }
        
        return [NSTimeZone timeZoneWithName:self.timeZoneArray[row]].abbreviation;
    }

    return nil;
    
}

- (IBAction)addTimeZone:(id)sender
{
    [self.window beginSheet:self.timezonePanel completionHandler:^(NSModalResponse returnCode) {
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
        self.messageLabel.stringValue = NSLocalizedString(@"MaximumTimezoneMessage", nil);
         [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
        return;
    }
    
    for (NSString *name in self.selectedTimeZones)
    {
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
            self.messageLabel.stringValue = NSLocalizedString(@"DuplicateTimezoneMessage", nil);
            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
            return;
        }
    }
    
        
    selectedTimezone = self.searchField.stringValue.length > 0 ?
                       self.filteredArray[self.availableTimezoneTableView.selectedRow] :
                        self.timeZoneArray[self.availableTimezoneTableView.selectedRow];
    
    [self.selectedTimeZones addObject:selectedTimezone];
    
    NSArray *defaultTimeZones = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPreferences"];
    NSMutableArray *newDefaults;
    
    if (defaultTimeZones == nil)
    {
        defaultTimeZones = [[NSMutableArray alloc] init];
    }
   
    newDefaults = [[NSMutableArray alloc] initWithArray:defaultTimeZones];
        
    [newDefaults addObject:selectedTimezone];
    
    [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:@"defaultPreferences"];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
    
    [self.timezonePanel close];
}

- (void)clearLabel
{
    self.messageLabel.stringValue = @"";
}

- (IBAction)closePanel:(id)sender
{
    [self.timezonePanel close];
}

- (IBAction)removeFromFavourites:(id)sender
{
    
    if ([self.timezoneTableView numberOfRows] == 1) {
        
        return;
    }
    
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
    
    [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:@"defaultPreferences"];
    
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", self.searchField.stringValue];
        
        self.filteredArray = [self.timeZoneArray filteredArrayUsingPredicate:predicate];
    }
    
    [self.availableTimezoneTableView reloadData];
}
- (IBAction)timeFormatSelectionChanged:(id)sender {
    
    NSButton *is24HourFormatSelected = (NSButton *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:is24HourFormatSelected.state] forKey:@"is24HourFormatSelected"];
    
    [self refreshMainTableview];
}

- (void)refreshMainTableview
{
    ApplicationDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    
    PanelController *panelController = appDelegate.panelController;
    
    [panelController updateDefaultPreferences];
    
    [panelController.mainTableview reloadData];

}

- (IBAction)showOnlyCityName:(id)sender {
    
    NSButton *checkbox = (NSButton *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:checkbox.state] forKey:@"showOnlyCity"];
    
    [self refreshMainTableview];
}

- (IBAction)startAppAtLogin:(id)sender
{
}

#pragma mark Reordering

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
    [pboard declareTypes:[NSArray arrayWithObject:@"public.text"] owner:self];
    
    [pboard setData:data forType:@"public.text"];
    
    return YES;
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pBoard = [info draggingPasteboard];
    
    NSData *data = [pBoard dataForType:@"public.text"];
    
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self.selectedTimeZones exchangeObjectAtIndex:rowIndexes.firstIndex withObjectAtIndex:row];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedTimeZones forKey:@"defaultPreferences"];
    
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

- (IBAction)supportAction:(id)sender
{
    /*
    NSAppleScript *mailScript;
    NSString *scriptString= @"tell application \"Mail\"\nset theAddress to \"abhishekbanthia@me.com\"\n set msg to make new outgoing message with properties {visible:true, subject:\"Regarding Clocker - We need to talk!\"}\ntell msg to make new to recipient at end of every to recipient with properties {address:theAddress}\n activate\nend tell";
    mailScript = [[NSAppleScript alloc] initWithSource:scriptString];
    NSDictionary *dict = nil;
    [mailScript executeAndReturnError:&dict];*/
    
    NSString *issuePage = @"https://github.com/Abhishaker17/Clocker/issues";
    NSURL *mainURL = [NSURL URLWithString:issuePage];
    [[NSWorkspace sharedWorkspace] openURL:mainURL];
}



@end
