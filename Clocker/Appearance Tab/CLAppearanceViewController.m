//
//  CLAppearanceViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/19/15.
//
//

#import "CLAppearanceViewController.h"
#import "ApplicationDelegate.h"
#import "PanelController.h"
#import "CommonStrings.h"
#import "CLTimezoneData.h"
#import "CLFloatingWindowController.h"

@interface CLAppearanceViewController ()
@property (weak) IBOutlet NSSegmentedControl *timeFormat;
@property (weak) IBOutlet NSSegmentedControl *theme;
@property (weak) IBOutlet NSTextField *informationLabel;
@property (assign, nonatomic) BOOL enableOptions;

@end

@implementation CLAppearanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];
    
    self.informationLabel.stringValue = @"Select a favourite timezone to enable menubar display options.";
    self.informationLabel.textColor = [NSColor secondaryLabelColor];
    
    self.enableOptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"favouriteTimezone"] == nil ? NO : YES;
    
    [self setAppropriateFont];
    
}


- (void)setAppropriateFont
{
    NSOperatingSystemVersion operatingSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    
    if (operatingSystemVersion.minorVersion <= 10)
    {
        //Set up Helvetica Neue font
         [self setFontFamily:@"HelveticaNeue-Light" forView:self.view andSubViews:YES];
    }
    
}

-(void)setFontFamily:(NSString*)fontFamily forView:(NSView*)view andSubViews:(BOOL)isSubViews
{
    if ([view isKindOfClass:[NSTextField class]])
    {
        NSTextField *labels = (NSTextField *)view;
        
        [labels setFont:[NSFont fontWithName:fontFamily size:[[labels font] pointSize]]];
    }
    
    if (isSubViews)
    {
        for (NSView *sview in view.subviews)
        {
            [self setFontFamily:fontFamily forView:sview andSubViews:YES];
        }
    }
}


- (IBAction)timeFormatSelectionChanged:(id)sender
{
    NSSegmentedControl *timeFormat = (NSSegmentedControl *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:timeFormat.selectedSegment] forKey:CL24hourFormatSelectedKey];
    
    [self refreshMainTableview:YES andUpdateFloatingWindow:YES];
}

- (IBAction)themeChanged:(id)sender
{
    NSSegmentedControl *themeSegment = (NSSegmentedControl *)sender;
    
    //Get the current display mode
    [self refreshMainTableview:NO andUpdateFloatingWindow:YES];
    
    ApplicationDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    PanelController *panelController = appDelegate.panelController;
    [panelController.backgroundView setNeedsDisplay:YES];
    
    if (themeSegment.selectedSegment == CLBlackTheme) {
        panelController.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        panelController.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
    }
    else
    {
        panelController.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        panelController.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
    }
    
    if (panelController.defaultPreferences.count == 0)
    {
        [panelController updatePanelColor];
    }
    
    [panelController.mainTableview reloadData];

}

- (IBAction)displayModeChanged:(id)sender
{
    NSSegmentedControl *modeSegment = (NSSegmentedControl *)sender;
    ApplicationDelegate *sharedDelege = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
    
    if (modeSegment.selectedSegment == 1)
    {
        sharedDelege.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [sharedDelege.floatingWindow showWindow:nil];
        [sharedDelege.floatingWindow updateDefaultPreferences];
        [sharedDelege.floatingWindow.mainTableview reloadData];
        [sharedDelege.floatingWindow startWindowTimer];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        sharedDelege.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [sharedDelege.floatingWindow.window close];
        [sharedDelege.panelController updateDefaultPreferences];
    }
}


- (IBAction)changeRelativeDayDisplay:(id)sender
{
    NSSegmentedControl *relativeDayControl = (NSSegmentedControl*) sender;
    NSNumber *selectedIndex = [NSNumber numberWithInteger:relativeDayControl.selectedSegment];
    [[NSUserDefaults standardUserDefaults] setObject:selectedIndex forKey:CLRelativeDateKey];
    [self refreshMainTableview:YES andUpdateFloatingWindow:YES];
}


- (void)refreshMainTableview:(BOOL)panel andUpdateFloatingWindow:(BOOL)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (panel)
        {
            ApplicationDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
            
            PanelController *panelController = appDelegate.panelController;
            
            [panelController updateDefaultPreferences];
            
            [panelController.mainTableview reloadData];
            
            [appDelegate.menubarController shouldIconBeUpdated:YES];
        }
        
        if (value)
        {
            //Get the current display mode
            NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
            
            if (displayMode.integerValue == 1)
            {
                //Get the Floating window instance
                for (NSWindow *window in [NSApplication sharedApplication].windows)
                {
                    if ([window.windowController isKindOfClass:[CLFloatingWindowController class]])
                    {
                        CLFloatingWindowController *currentInstance = (CLFloatingWindowController *)window.windowController;
                        [currentInstance.mainTableview reloadData];
                        
                        //Only one instance where we need to update panel color and in that instance we pass panel as NO
                        
                        if (!panel)
                        {
                             [currentInstance updatePanelColor];
                        }
                    }
                }
            }
        }
    });
}

- (IBAction)changeMenuBarDisplayPreferences:(id)sender
{
    NSSegmentedControl *segmentedControl = (NSSegmentedControl *)sender;
    NSNumber *shouldDayBeShown = [NSNumber numberWithBool:[segmentedControl isSelectedForSegment:0]];
    NSNumber *shouldCityBeShown = [NSNumber numberWithBool:[segmentedControl isSelectedForSegment:1]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:shouldDayBeShown forKey:@"shouldDayBeShown"];
    [userDefaults setObject:shouldCityBeShown forKey:@"shouldCityBeShown"];
}

- (IBAction)showFutureSlider:(id)sender
{
    //Get the current display mode
    [self refreshMainTableview:NO andUpdateFloatingWindow:YES];
}

@end
