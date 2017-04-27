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
#import "CLTimezoneData.h"
#import "CLAPIConnector.h"
#import "EDSunriseSet.h"
#import "NSString+CLStringAdditions.h"
#import "CLTimezoneDataOperations.h"
#import "MoLoginItem/MoLoginItem.h"

NSString *const CLSearchPredicateKey = @"SELF CONTAINS[cd]%@";
NSString *const CLPreferencesTimezoneNameIdentifier = @"formattedAddress";
NSString *const CLPreferencesCustomLabelIdentifier = @"label";
NSString *const CLPreferencesAvailableTimezoneIdentifier = @"availableTimezones";
NSString *const CLNoTimezoneSelectedErrorMessage =  @"Please select a timezone!";
NSString *const CLMaxTimezonesErrorMessage =  @"Maximum 10 timezones allowed!";
NSString *const CLTimezoneAlreadySelectedError = @"Timezone has already been selected!";
NSString *const CLMaxCharactersReachedError = @"Only 50 characters allowed!";
NSString *const CLNoInternetConnectivityError = @"You're offline, maybe?";
NSString *const CLTimezoneSearchURL = @"https://maps.googleapis.com/maps/api/timezone/json?location=%@&timestamp=%f&key=AIzaSyCyf2knCi6KiKuDJLYDBD3Odq5dt4c-_KI";
NSString *const CLTryAgainMessage = @"Try again, maybe?";

@interface CLPreferencesViewController ()
@property (weak) IBOutlet NSTextField *placeholderLabel;
@property (assign) BOOL activityInProgress;
@property (strong, nonatomic) NSMutableArray *selectedTimeZones;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (nonatomic, strong) NSMutableArray *timeZoneArray;
@property (nonatomic, strong) NSMutableArray *timeZoneFilteredArray;
@property (nonatomic, copy) NSString *columnName;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (weak) IBOutlet SRRecorderControl *recorderControl;
@property (weak) IBOutlet NSTableView *timezoneTableView;
@property (strong) IBOutlet Panel *timezonePanel;
@property (weak) IBOutlet NSTableView *availableTimezoneTableView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTextField *messageLabel;
@property (weak) IBOutlet NSSegmentedControl *searchCriteria;
@property (weak) IBOutlet NSTableColumn *abbreviation;

@end

@implementation CLPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refereshTimezoneTableView)
                                                 name:CLCustomLabelChangedNotification
                                               object:nil];
    
    [self refereshTimezoneTableView];
    
    [self setUpViewAndInitializeDefaults];

    [self.availableTimezoneTableView reloadData];
    
    [self setUpShortcutObserver];
}

- (void)refereshTimezoneTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *defaultTimeZones = [[NSUserDefaults standardUserDefaults]
                                            objectForKey:CLDefaultPreferenceKey];
        
        self.selectedTimeZones = [[NSMutableArray alloc] initWithArray:defaultTimeZones];
        
        [self.timezoneTableView reloadData];
    });
}


- (void) setUpViewAndInitializeDefaults
{
    self.placeholderLabel.hidden = YES;
    
    if (!self.filteredArray)
    {
        self.timeZoneArray = [[NSMutableArray alloc] initWithArray:[NSTimeZone knownTimeZoneNames]];
        self.timeZoneFilteredArray = [NSMutableArray new];
        self.filteredArray = [NSMutableArray new];
    }
    
    self.messageLabel.stringValue = CLEmptyString;
    
    self.columnName = @"Place(s)";
    
    [self.timezoneTableView registerForDraggedTypes: @[CLDragSessionKey]];
}

- (void)setUpShortcutObserver
{
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    
    [self.recorderControl bind:NSValueBinding
                      toObject:defaults
                   withKeyPath:@"values.globalPing"
                       options:nil];
    self.recorderControl.delegate = self;
    
    [defaults addObserver:self
               forKeyPath:@"values.globalPing"
                  options:NSKeyValueObservingOptionInitial
                  context:NULL];
}


-(void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary<NSString *,id> *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"values.globalPing"])
    {
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];
        
        NSDictionary *newShortcut = [anObject valueForKeyPath:aKeyPath];
        
        if (newShortcut && (NSNull *)newShortcut != [NSNull null])
        {
            PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath
                                                        keyCombo:newShortcut
                                                          target:self
                                                          action:@selector(ping:)];
            [hotKeyCenter registerHotKey:newHotKey];
            
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] pause];
    return YES;
}

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder
{
    [[PTHotKeyCenter sharedCenter] resume];
}

-(IBAction)ping:(id)sender
{
    ApplicationDelegate *delegate = (ApplicationDelegate *)[NSApplication sharedApplication].delegate;
    [delegate togglePanel:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CLCustomLabelChangedNotification object:nil];

    [[NSUserDefaultsController sharedUserDefaultsController]
     removeObserver:self forKeyPath:@"values.globalPing"];
    
}

-(BOOL)acceptsFirstResponder
{
    NSLog(@"Accepts first responder");
    return YES;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger numberOfRows = 0;
    
    if (tableView == self.timezoneTableView)
    {
        numberOfRows = self.selectedTimeZones.count;
    }
    else
    {
        numberOfRows = [self numberOfSearchResults];
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfSearchResults
{
    NSInteger searchCriteria = (self.searchCriteria).selectedSegment;
    
    if (searchCriteria == 0) {
        return self.filteredArray.count;
    }
    
    if (self.searchField.stringValue.length > 0) {
        return self.timeZoneFilteredArray.count;
    }
    
    return self.timeZoneArray.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    CLTimezoneData *dataSource, *selectedDataSource;
    
    if (self.filteredArray.count > row)
    {
         dataSource = self.filteredArray[row];
    }
    
    if (self.selectedTimeZones.count > row) {
          selectedDataSource = [CLTimezoneData getCustomObject:self.selectedTimeZones[row]];
    }
    
    if ([tableColumn.identifier isEqualToString:CLPreferencesTimezoneNameIdentifier])
    {
        if ((selectedDataSource.formattedAddress).length > 0) {
           return selectedDataSource.formattedAddress;
        }
        return selectedDataSource.timezoneID;
    }
    else if([tableColumn.identifier isEqualToString:CLPreferencesAvailableTimezoneIdentifier])
    {
        NSInteger searchCriteria = (self.searchCriteria).selectedSegment;
        
        if (searchCriteria == 0)
        {
            if (row < self.filteredArray.count)
            {
                return dataSource.formattedAddress;
            }

        }
        else
        {
            if (self.searchField.stringValue.length > 0)
            {
                if (row < self.timeZoneFilteredArray.count) {
                    return self.timeZoneFilteredArray[row];
                }
            }
            
            return self.timeZoneArray[row];
        }
        return nil;
    }
    else if([tableColumn.identifier isEqualToString:CLPreferencesCustomLabelIdentifier])
    {
        return selectedDataSource.customLabel;
    }
    else if ([tableColumn.identifier isEqualToString:@"favouriteTimezone"])
    {
        return selectedDataSource.isFavourite;
    }
    else if ([tableColumn.identifier isEqualToString:@"abbreviation"])
    {
        if (self.searchField.stringValue.length > 0)
        {
            if (row < self.timeZoneFilteredArray.count)
            {
                return [NSTimeZone timeZoneWithName:self.timeZoneFilteredArray[row]].abbreviation;
            }
            
        }
        
        if (self.timeZoneArray.count > row)
        {
            return [NSTimeZone timeZoneWithName:self.timeZoneArray[row]].abbreviation;
        }
       

    }
    
    return nil;
    
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([object isKindOfClass:[NSString class]])
    {
        
        NSString *originalValue = (NSString *)object;
        NSString *formattedValue = [originalValue stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]];
        
        CLTimezoneData *dataObject = [CLTimezoneData getCustomObject:self.selectedTimeZones[row]];
        [dataObject setLabelForTimezone:formattedValue];
        
        [self insertTimezoneInDefaultPreferences:dataObject atIndex:row];
        
        if ([dataObject.isFavourite isEqualToNumber:@1])
        {
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:dataObject]
                                                      forKey:@"favouriteTimezone"];
        }

    }
    else
    {
        [self resetAllFavouriteValues];
        
        NSNumber *isFavouriteValue = (NSNumber *)object;
        
        CLTimezoneData *dataObject = [CLTimezoneData getCustomObject:self.selectedTimeZones[row]];
        [dataObject setFavouriteValueForTimezone:isFavouriteValue];
        
        [self insertTimezoneInDefaultPreferences:dataObject atIndex:row];
        
        ApplicationDelegate *appDelegate = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
        
        if (dataObject.isFavourite.integerValue == 1)
        {
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:dataObject]
                                                      forKey:@"favouriteTimezone"];
            [appDelegate.menubarController setUpTimerForUpdatingMenubar];
            
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setObject:nil
                                                      forKey:@"favouriteTimezone"];
            [appDelegate.menubarController invalidateTimerForMenubar];
        }
        
        [self refereshTimezoneTableView];
        
    }
    
    [self refreshMainTableview];
}

- (void)resetAllFavouriteValues
{
    NSMutableArray *newArray = [NSMutableArray new];
    
    [self.selectedTimeZones enumerateObjectsUsingBlock:^(NSData *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
     {
         CLTimezoneData *timezone = [CLTimezoneData getCustomObject:obj];
         [timezone setFavouriteValueForTimezone:@0];
         NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:timezone];
         [newArray addObject:encodedObject];
         
     }];
    
    self.selectedTimeZones = [NSMutableArray arrayWithArray:newArray];
}

- (void)insertTimezoneInDefaultPreferences:(CLTimezoneData *)timezoneObject atIndex:(NSInteger)index
{
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:timezoneObject];
    self.selectedTimeZones[index] = encodedObject;
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedTimeZones forKey:CLDefaultPreferenceKey];
}

- (IBAction)addTimeZone:(id)sender
{
    self.abbreviation.hidden = YES;
    
    self.filteredArray = [NSMutableArray new];
    
    self.searchCriteria.selectedSegment = 0;
    
    [self.view.window beginSheet:self.timezonePanel
               completionHandler:nil];
}

- (IBAction)addToFavorites:(id)sender
{
    self.activityInProgress = YES;
    
    if (self.availableTimezoneTableView.selectedRow == -1)
    {
        self.messageLabel.stringValue = CLNoTimezoneSelectedErrorMessage;
        [NSTimer scheduledTimerWithTimeInterval:5 target:self
                                       selector:@selector(clearLabel)
                                       userInfo:nil
                                        repeats:NO];
        self.activityInProgress = NO;
        return;
    }
    
    if (self.selectedTimeZones.count >= 20)
    {
        self.messageLabel.stringValue = CLMaxTimezonesErrorMessage;
        [NSTimer scheduledTimerWithTimeInterval:5 target:self
                                       selector:@selector(clearLabel)
                                       userInfo:nil
                                        repeats:NO];
        self.activityInProgress = NO;
        return;
    }
    
    
    if (self.searchCriteria.selectedSegment == 0)
    {
        CLTimezoneData *dataObject = self.filteredArray[self.availableTimezoneTableView.selectedRow];
        
        
        [self.selectedTimeZones enumerateObjectsUsingBlock:^(NSData *  _Nonnull encodedData, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:encodedData];
            NSString *name = timezoneObject.place_id;
            NSString *selectedPlaceID = dataObject.place_id;
            
            if (self.searchField.stringValue.length > 0) {
                if ([name isKindOfClass:[NSString class]] &&
                    [name isEqualToString:selectedPlaceID])
                {
                    self.messageLabel.stringValue = CLTimezoneAlreadySelectedError;
                    [NSTimer scheduledTimerWithTimeInterval:5
                                                     target:self
                                                   selector:@selector(clearLabel) userInfo:nil
                                                    repeats:NO];
                    self.activityInProgress = NO;
                    return;
                }
            }
            
            
        }];
        
        self.searchField.stringValue = CLEmptyString;
        
        [self getTimeZoneForLatitude:dataObject.latitude
                        andLongitude:dataObject.longitude];
    }
    else
    {
        CLTimezoneData *data = [CLTimezoneData new];
        [data setLabelForTimezone:CLEmptyString];
        
        if (self.searchField.stringValue.length > 0)
        {
            [data setIDForTimezone:self.timeZoneFilteredArray[self.availableTimezoneTableView.selectedRow]];
            [data setFormattedAddressForTimezone:self.timeZoneFilteredArray[self.availableTimezoneTableView.selectedRow]];
            
        }
        else
        {
            [data setIDForTimezone:self.timeZoneArray[self.availableTimezoneTableView.selectedRow]];
            [data setFormattedAddressForTimezone:self.timeZoneArray[self.availableTimezoneTableView.selectedRow]];
        }
        
        CLTimezoneDataOperations *operationObject = [[CLTimezoneDataOperations alloc] initWithTimezoneData:data];
        
        [operationObject save];
        
        self.timeZoneFilteredArray = [NSMutableArray array];
        
        self.timeZoneArray = [NSMutableArray new];
        
        [self.availableTimezoneTableView reloadData];
        
        [self refereshTimezoneTableView];
        
        [self refreshMainTableview];
        
        [self.timezonePanel close];
        
        self.placeholderLabel.placeholderString = CLEmptyString;
        
        self.searchField.stringValue = CLEmptyString;
        
        self.searchField.placeholderString = @"Enter a city, state or country name";
        
        self.availableTimezoneTableView.hidden = NO;
        
        self.activityInProgress = NO;
    }
}

- (IBAction)closePanel:(id)sender
{
    self.filteredArray = [NSMutableArray array];
    self.timeZoneArray = [NSMutableArray new];
    self.searchCriteria.selectedSegment = 0;
    self.columnName = @"Place(s)";
    [self.availableTimezoneTableView reloadData];
    self.searchField.stringValue = CLEmptyString;
    self.placeholderLabel.placeholderString = CLEmptyString;
    self.searchField.placeholderString = @"Enter a city, state or country name";
    [self.timezonePanel close];
    self.activityInProgress = NO;
}

- (void)clearLabel
{
    self.messageLabel.stringValue = CLEmptyString;
}

- (IBAction)removeFromFavourites:(id)sender
{
    NSMutableArray *itemsToRemove = [NSMutableArray array];
    
    if (self.timezoneTableView.selectedRow == -1)
    {
        return;
    }
    
    [self.timezoneTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        
        CLTimezoneData *dataObject = [CLTimezoneData getCustomObject:self.selectedTimeZones[idx]];
        
        if (dataObject.isFavourite.integerValue == 1)
        {
            //Remove favourite from standard defaults
            [[NSUserDefaults standardUserDefaults] setObject:nil
                                                      forKey:@"favouriteTimezone"];
            
        }
        
        [itemsToRemove addObject:self.selectedTimeZones[idx]];
        
    }];
    
    [self.selectedTimeZones removeObjectsInArray:itemsToRemove];
    
    NSMutableArray *newDefaults = [[NSMutableArray alloc] initWithArray:self.selectedTimeZones];
    
    [[NSUserDefaults standardUserDefaults] setObject:newDefaults forKey:CLDefaultPreferenceKey];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
    
    if (self.selectedTimeZones.count == 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"favouriteTimezone"];
    }
    
}

- (IBAction)filterTimezoneArray:(id)sender
{
    if (self.searchField.stringValue.length > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:CLSearchPredicateKey, self.searchField.stringValue];
        
        self.timeZoneFilteredArray = [NSMutableArray arrayWithArray:[self.timeZoneArray filteredArrayUsingPredicate:predicate]];
        
        [self.availableTimezoneTableView reloadData];
    }
}


- (IBAction)filterArray:(id)sender
{
    if (self.searchCriteria.selectedSegment == 1)
    {
        [self filterTimezoneArray:sender];
        return;
    }
    
    [self clearLabel];
    
    self.filteredArray = [NSMutableArray array];
    
    if (self.searchField.stringValue.length > 50)
    {
        self.activityInProgress = NO;
        self.messageLabel.stringValue = CLMaxCharactersReachedError;
        [NSTimer scheduledTimerWithTimeInterval:10
                                         target:self
                                       selector:@selector(clearLabel)
                                       userInfo:nil
                                        repeats:NO];
        return;
    }
    
    if (self.searchField.stringValue.length > 0)
    {
        [self callGoogleAPiWithSearchString:self.searchField.stringValue];
    }
    else
    {
        if (self.dataTask.state == NSURLSessionTaskStateRunning) {
            [self.dataTask cancel];
        }
        self.activityInProgress = NO;
        self.placeholderLabel.placeholderString = CLEmptyString;
    }
    
    [self.availableTimezoneTableView reloadData];
}



- (void)refreshMainTableview
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        PanelController *panelController = [PanelController getPanelControllerInstance];
        
        [panelController updateDefaultPreferences];
        
        [panelController updateTableContent];
        
        //Get the current display mode
        NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
        
        if (displayMode.integerValue == 1)
        {
            CLFloatingWindowController *currentInstance = [CLFloatingWindowController sharedFloatingWindow];
            
            [currentInstance updateDefaultPreferences];
                    
            [currentInstance updateTableContent];
        }

    });
}

#pragma mark Reordering

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
    [pboard declareTypes:@[CLDragSessionKey] owner:self];
    
    [pboard setData:data forType:CLDragSessionKey];
    
    return YES;
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    if (row == self.selectedTimeZones.count)
    {
        row--;
    }
    
    NSPasteboard *pBoard = [info draggingPasteboard];
    
    NSData *data = [pBoard dataForType:CLDragSessionKey];
    
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self.selectedTimeZones exchangeObjectAtIndex:rowIndexes.firstIndex withObjectAtIndex:row];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedTimeZones forKey:CLDefaultPreferenceKey];
    
    [self.timezoneTableView reloadData];
    
    [self refreshMainTableview];
    
    [self.timezoneTableView deselectRow:self.timezoneTableView.selectedRow];
    
    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView
               validateDrop:(id<NSDraggingInfo>)info
                proposedRow:(NSInteger)row
      proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationEvery;
}

- (void)callGoogleAPiWithSearchString:(NSString *)searchString
{
    if (self.dataTask.state == NSURLSessionTaskStateRunning)
    {
        [self.dataTask cancel];
    }
    
    NSString *userPreferredLanguage = [NSLocale preferredLanguages][0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.availableTimezoneTableView.isHidden)
        {
            self.availableTimezoneTableView.hidden = NO;
        }
        
        self.placeholderLabel.hidden = NO;
        
        if (![CLAPIConnector isUserConnectedToInternet]) {
            self.placeholderLabel.stringValue = CLNoInternetConnectivityError;
            return;
        }
        
    });
    
    self.activityInProgress = YES;
    
    self.placeholderLabel.placeholderString = [NSString stringWithFormat:@"Searching for '%@'", searchString];
    
    NSArray* words = [searchString componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    searchString = [words componentsJoinedByString:CLEmptyString];
    
    NSString *urlString = [NSString stringWithFormat:CLLocationSearchURL, searchString, userPreferredLanguage];
    
    [CLAPIConnector dataTaskWithServicePath:urlString
                          bySender:self
               withCompletionBlock:^(NSError *error, NSDictionary *json) {
                   
                   
                   dispatch_async(dispatch_get_main_queue(), ^{
                       
                       if (error)
                       {
                           self.placeholderLabel.placeholderString = [error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."] ?
                           CLNoInternetConnectivityError : CLTryAgainMessage;
                           self.activityInProgress = NO;
                           return;
                       }
                       
                       self.placeholderLabel.placeholderString = CLEmptyString;
                       
                       if ([json[@"status"] isEqualToString:@"ZERO_RESULTS"]) {
                           self.placeholderLabel.placeholderString = @"No results! 😔 Try entering the exact name.";
                           self.activityInProgress = NO;
                           return;
                       }
                       
                       
                       [json[@"results"] enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
                           NSDictionary *latLang = dictionary[@"geometry"][@"location"];
                           NSString *latitude = latLang[@"lat"];
                           NSString *longitude = latLang[@"lng"];
                           NSString *formattedAddress = dictionary[@"formatted_address"];
                           
                           NSDictionary *totalPackage = @{@"latitude":latitude,
                                                          @"longitude" : longitude,
                                                          CLTimezoneName:formattedAddress,
                                                          CLCustomLabel: CLEmptyString,
                                                          CLTimezoneID : CLEmptyString,
                                                          CLPlaceIdentifier : dictionary[CLPlaceIdentifier]};
                           
                           CLTimezoneData *newObject = [[CLTimezoneData alloc] initWithDictionary:totalPackage];
                           
                           [self.filteredArray addObject:newObject];
                       }];
                       
                       self.activityInProgress = NO;
                       
                       [self.availableTimezoneTableView reloadData];
                       
                   });
                   
               }];
}

- (void)getTimeZoneForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude
{
    if (self.placeholderLabel.isHidden)
    {
        self.placeholderLabel.hidden = NO;
    }
    
    if (![CLAPIConnector isUserConnectedToInternet]) {
        
        [self resetStateAndShowDisconnectedMessage];
        
        return;
    }
    
    self.searchField.placeholderString = @"Fetching data might take some time!";
    
    self.placeholderLabel.placeholderString = @"Retrieving timezone data";
    
    self.availableTimezoneTableView.hidden = YES;
    
    NSString *tuple = [NSString stringWithFormat:@"%@,%@", latitude, longitude];
    
    NSTimeInterval timestamp = [NSDate date].timeIntervalSince1970;
    
    NSString *urlString = [NSString stringWithFormat:CLTimezoneSearchURL, tuple, timestamp];
    
    [CLAPIConnector dataTaskWithServicePath:urlString
                          bySender:self
               withCompletionBlock:^(NSError *error, NSDictionary *json) {
                   
                   if (!error)
                   {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           
                           [self handleEdgeCasesForResponse:json];
                           
                           if (self.availableTimezoneTableView.selectedRow >=0 && self.availableTimezoneTableView.selectedRow < self.filteredArray.count)
                           {
                                   CLTimezoneData *dataObject = self.filteredArray[self.availableTimezoneTableView.selectedRow];
                        
                               NSString *filteredAddress = [dataObject.formattedAddress getFilteredNameForPlace];
                               
                               NSMutableDictionary *newTimezone = [NSMutableDictionary dictionary];
                               
                               newTimezone[CLTimezoneID] = json[@"timeZoneId"];
                               
                               
                               newTimezone[CLTimezoneName] = filteredAddress;
                               newTimezone[CLPlaceIdentifier] = dataObject.place_id;
                               newTimezone[@"latitude"] = dataObject.latitude;
                               newTimezone[@"longitude"] = dataObject.longitude;
                               newTimezone[@"nextUpdate"] = CLEmptyString;
                               newTimezone[CLCustomLabel] = CLEmptyString;
                               
                               
                               CLTimezoneData *timezoneObject = [[CLTimezoneData alloc] initWithDictionary:newTimezone];
                               
                               CLTimezoneDataOperations *operationObject = [[CLTimezoneDataOperations alloc] initWithTimezoneData:timezoneObject];
                               
                               [operationObject save];

                           }
                           
                           [self updateViewState];
                           
                       });
                   }
                   else
                   {
                       self.placeholderLabel.placeholderString = [error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."] ?
                       CLNoInternetConnectivityError : CLTryAgainMessage;
                       
                       self.activityInProgress = NO;
                       
                   }
               }];
    
}

- (void)resetStateAndShowDisconnectedMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.placeholderLabel.placeholderString = CLNoInternetConnectivityError;
        self.activityInProgress = NO;
        self.filteredArray = [NSMutableArray array];
        [self.availableTimezoneTableView reloadData];
    });
}

- (void)handleEdgeCasesForResponse:(NSDictionary *)json
{
    if (json.count == 0) {
        self.activityInProgress = NO;
        self.placeholderLabel.placeholderString = @"No results found! ! 😔 Try Again?";
        return;
    }
    
    if ([json[@"status"] isEqualToString:@"ZERO_RESULTS"]) {
        self.placeholderLabel.placeholderString = @"No results! 😔 Try entering the exact name.";
        self.activityInProgress = NO;
        return;
    }

}

- (void)updateViewState
{
    self.filteredArray = [NSMutableArray array];
    
    [self.availableTimezoneTableView reloadData];
    
    [self refereshTimezoneTableView];
    
    [self refreshMainTableview];
    
    [self.timezonePanel close];
    
    self.placeholderLabel.placeholderString = CLEmptyString;
    
    self.searchField.placeholderString = @"Enter a city, state or country name";
    
    self.availableTimezoneTableView.hidden = NO;
    
    self.activityInProgress = NO;
}

- (IBAction)searchOptions:(id)sender
{
    self.placeholderLabel.placeholderString = CLEmptyString;
    self.placeholderLabel.hidden = YES;
    
    if (self.searchCriteria.selectedSegment == 0)
    {
        self.searchField.placeholderString = @"Enter a city, state or country name";
        self.columnName = @"Place(s)";
        self.abbreviation.hidden = YES;
    }
    else
    {
        self.searchField.placeholderString = @"Enter a timezone name";
        self.columnName = @"Timezone(s)";
        self.abbreviation.hidden = NO;
        self.timeZoneArray = [NSMutableArray arrayWithArray:[NSTimeZone knownTimeZoneNames]];
    }
    
    self.searchField.stringValue = CLEmptyString;
    [self.availableTimezoneTableView reloadData];
}

- (IBAction)loginPreferenceChanged:(NSButton *)sender
{
        MOEnableLoginItem(sender.state == NSOnState);
}

@end
