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
#import "Reachability.h"


NSString *const CLSearchPredicateKey = @"SELF CONTAINS[cd]%@";
NSString *const CLPreferencesViewNibIdentifier = @"PreferencesWindow";
NSString *const CLPreferencesTimezoneNameIdentifier = @"formattedAddress";
NSString *const CLPreferencesAbbreviationIdentifier = @"abbreviation";
NSString *const CLPreferencesCustomLabelIdentifier = @"label";
NSString *const CLPreferencesAvailableTimezoneIdentifier = @"availableTimezones";

@interface CLPreferencesViewController ()
@property (weak) IBOutlet NSTextField *placeholderLabel;
@property (assign) BOOL activityInProgress;

@property (weak) IBOutlet NSTableView *timezoneTableView;
@property (strong) IBOutlet Panel *timezonePanel;
@property (weak) IBOutlet NSSegmentedControl *theme;
@property (weak) IBOutlet NSPopUpButton *fontPopUp;
@property (weak) IBOutlet NSTableView *availableTimezoneTableView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSSegmentedControl *timeFormat;
@property (weak) IBOutlet NSTextField *messageLabel;

@end

@implementation CLPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES];
    [self.view setLayer:viewLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refereshTimezoneTableView) name:CLCustomLabelChangedNotification object:nil];
    self.placeholderLabel.hidden = YES;
    
    [self refereshTimezoneTableView];
    
    if (!self.filteredArray)
    {
        self.filteredArray = [[NSMutableArray alloc] init];
    }
    
    self.messageLabel.stringValue = CLEmptyString;

    [self.availableTimezoneTableView reloadData];
    
    //Register for drag and drop
    [self.timezoneTableView registerForDraggedTypes: [NSArray arrayWithObject: CLDragSessionKey]];
    
    NSMutableArray *availableFonts = [[NSMutableArray alloc] init];
    
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
        return self.filteredArray.count;
    }
    
    return 0;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:CLPreferencesTimezoneNameIdentifier])
    {
        if ([self.selectedTimeZones[row][CLTimezoneName] length] > 0) {
           return self.selectedTimeZones[row][CLTimezoneName];
        }
        return self.selectedTimeZones[row][CLTimezoneID];
    }
    else if([[tableColumn identifier] isEqualToString:CLPreferencesAvailableTimezoneIdentifier])
    {
        if (row < self.filteredArray.count)
        {
            return [self.filteredArray[row] objectForKey:CLTimezoneName];
        }
        
        return nil;
    }
    else if([[tableColumn identifier] isEqualToString:CLPreferencesCustomLabelIdentifier])
    {
        return self.selectedTimeZones[row][CLCustomLabel];
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
    self.activityInProgress = YES;

    if (self.availableTimezoneTableView.selectedRow == -1)
    {
        self.messageLabel.stringValue = @"Please select a timezone!";
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
        self.activityInProgress = NO;
        return;
    }

    NSString *selectedTimezone;
    
    if (self.selectedTimeZones.count >= 10)
    {
        self.messageLabel.stringValue = @"Maximum 10 timezones allowed!";
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
        self.activityInProgress = NO;
        return;
    }
    
    for (NSDictionary *timezoneDictionary in self.selectedTimeZones)
    {
        NSString *name = timezoneDictionary[@"place_id"];
        NSString *selectedPlaceID = [self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:@"place_id"];
        
        if (self.searchField.stringValue.length > 0) {
            if ([name isKindOfClass:[NSString class]] &&
                [name isEqualToString:selectedPlaceID])
            {
                self.messageLabel.stringValue = @"Timezone has already been selected!";
                [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
                self.activityInProgress = NO;
                return;
            }
        }
    }
    
    selectedTimezone = self.filteredArray[self.availableTimezoneTableView.selectedRow];
    
    self.searchField.stringValue = CLEmptyString;
    
   [self getTimeZoneForLatitude:[self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:@"latitude"] andLongitude:[self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:@"longitude"]];
}

- (IBAction)closePanel:(id)sender {

        self.filteredArray = [NSMutableArray array];
        self.placeholderLabel.placeholderString = CLEmptyString;
        [self.availableTimezoneTableView reloadData];
        self.searchField.stringValue = CLEmptyString;
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
    self.filteredArray = [NSMutableArray array];
    
    if (self.searchField.stringValue.length > 0)
    {
        [self callGoogleAPiWithSearchString:self.searchField.stringValue];
    }
    else
    {
        if (self.dataTask.state == NSURLSessionTaskStateRunning) {
            [self.dataTask cancel];
        }
        
        self.placeholderLabel.placeholderString = CLEmptyString;
    }
        
    [self.availableTimezoneTableView reloadData];
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

- (void)refreshMainTableview
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ApplicationDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        
        PanelController *panelController = appDelegate.panelController;
        
        [panelController updateDefaultPreferences];
        
        [panelController.mainTableview reloadData];
        
    });
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

- (void)callGoogleAPiWithSearchString:(NSString *)searchString
{
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        [self.dataTask cancel];
    }
    
        self.placeholderLabel.hidden = NO;
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable)
    {
        self.placeholderLabel.placeholderString = @"You're offline, maybe?";
        return;
    }
    
    self.activityInProgress = YES;

    self.placeholderLabel.placeholderString = [NSString stringWithFormat:@"Searching for '%@'", searchString];
    
    NSArray* words = [searchString componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    searchString = [words componentsJoinedByString:@""];
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=AIzaSyCyf2knCi6KiKuDJLYDBD3Odq5dt4c-_KI", searchString];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSError *error = nil;
    
    if (!error) {
        
        self.dataTask= [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
        
                if (httpResp.statusCode == 200) {
                    
                     dispatch_async(dispatch_get_main_queue(), ^{

                      self.placeholderLabel.placeholderString = CLEmptyString;
                         
                         NSDictionary* json = [NSJSONSerialization
                                               JSONObjectWithData:data
                                               options:kNilOptions
                                               error:nil];
                         
                         if ([json[@"status"] isEqualToString:@"ZERO_RESULTS"]) {
                             self.placeholderLabel.placeholderString = @"No results found! 😔";
                             self.activityInProgress = NO;
                             return;
                         }
                         
                         for (NSDictionary *dictionary in json[@"results"])
                         {
                             NSDictionary *latLang = [[dictionary objectForKey:@"geometry"] objectForKey:@"location"];
                             NSString *latitude = latLang[@"lat"];
                             NSString *longitude = latLang[@"lng"];
                             NSString *formattedAddress = [dictionary objectForKey:@"formatted_address"];
                             
                             NSDictionary *totalPackage = @{@"latitude":latitude,
                                                            @"longitude" : longitude,
                                                            CLTimezoneName:formattedAddress,
                                                            @"customLabel" : @"",
                                                            @"timezoneID" : @"",
                                                            CLPlaceIdentifier : dictionary[@"place_id"]};
                             [self.filteredArray addObject:totalPackage];
                             
                         }
                         self.activityInProgress = NO;
                         
                         [self.availableTimezoneTableView reloadData];

                     });
                  
                    }
                else
                {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.placeholderLabel.placeholderString = [error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."] ?
                         @"You're offline, maybe?" : @"Try again, maybe?";
                         self.activityInProgress = NO;
                     });
               
                }
            }
            
        }];
        [self.dataTask resume];
        
    }
}

- (void)getTimeZoneForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
        self.placeholderLabel.placeholderString = @"You're offline, maybe?";
        self.activityInProgress = NO;
        self.filteredArray = [NSMutableArray array];
        [self.availableTimezoneTableView reloadData];
        });
        
        return;
    }
    
    self.searchField.placeholderString = [NSString stringWithFormat:@"Adding %@", [self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:CLTimezoneName]];

    self.placeholderLabel.placeholderString = @"Retrieving timezone data";
  
    self.availableTimezoneTableView.hidden = YES;
    
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
        
        self.dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (httpResp.statusCode == 200) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSDictionary* json = [NSJSONSerialization
                                              JSONObjectWithData:data
                                              options:kNilOptions
                                              error:nil];
                        
                        if (json.count == 0) {
                            self.placeholderLabel.placeholderString = @"No results found";
                            return;
                        }
                        
                        
                        NSString *filteredAddress = [self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:CLTimezoneName];
                        NSRange range = [filteredAddress rangeOfString:@","];
                        if (range.location != NSNotFound)
                        {
                            filteredAddress = [[self.filteredArray[self.availableTimezoneTableView.selectedRow] objectForKey:CLTimezoneName ] substringWithRange:NSMakeRange(0, range.location)];
                        }
                        
                        NSDictionary *newTimezone = @{CLTimezoneID: json[@"timezoneId"],
                                                      @"sunriseTime" : json[@"sunrise"],
                                                      @"sunsetTime": json[@"sunset"],
                                                      CLCustomLabel : @"",
                                                      CLTimezoneName : filteredAddress,
                                                      CLPlaceIdentifier : self.filteredArray[self.availableTimezoneTableView.selectedRow][CLPlaceIdentifier]};
                        
                        NSArray *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
                        
                        if (defaultPreference == nil)
                        {
                            defaultPreference = [[NSMutableArray alloc] init];
                        }
                        
                        NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:defaultPreference];
                        [newArray addObject:newTimezone];
                        
                        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:CLDefaultPreferenceKey];
                        
                        self.filteredArray = [NSMutableArray array];
                        
                        [self.availableTimezoneTableView reloadData];

                        [self refereshTimezoneTableView];
                        
                        [self refreshMainTableview];
                        
                        [self.timezonePanel close];
                        
                        self.availableTimezoneTableView.hidden = NO;
                        
                        self.placeholderLabel.placeholderString = CLEmptyString;
                        
                        self.searchField.placeholderString = @"Enter a city, state or country name";
                        
                        self.activityInProgress = NO;
                        
                    });
                }
            }
            else
            {
                self.placeholderLabel.placeholderString = [error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."] ?
                @"You're offline, maybe?" : @"Try again, maybe?";
                
                self.activityInProgress = NO;
            }
            
        }];
        
        [self.dataTask resume];
        
    }
}

@end
