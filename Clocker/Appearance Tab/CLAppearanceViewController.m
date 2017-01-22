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
#import <Crashlytics/Crashlytics.h>

typedef NS_ENUM(NSUInteger, CLClockerMode) {
    CLMenubarMode = 0,
    CLFloatingMode
};

@interface CLAppearanceViewController ()
@property (weak) IBOutlet NSSegmentedControl *timeFormat;
@property (weak) IBOutlet NSSegmentedControl *theme;
@property (weak) IBOutlet NSTextField *informationLabel;
@property (assign, nonatomic) BOOL enableOptions;

@end

@implementation CLAppearanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.informationLabel.stringValue = @"Select a favourite timezone to enable menubar display options.";
    self.informationLabel.textColor = [NSColor secondaryLabelColor];
    
    self.enableOptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"favouriteTimezone"] == nil ? NO : YES;
    
}

- (IBAction)timeFormatSelectionChanged:(id)sender
{
    NSSegmentedControl *timeFormat = (NSSegmentedControl *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:@(timeFormat.selectedSegment) forKey:CL24hourFormatSelectedKey];
    
    [Answers logCustomEventWithName:@"Time Format Selected" customAttributes:@{@"Time Format" : timeFormat.selectedSegment == 0 ? @"12 Hour Format" : @"24 Hour Format"}];
    
    [self refreshMainTableview:YES andUpdateFloatingWindow:YES];
}

- (IBAction)themeChanged:(id)sender
{
    NSSegmentedControl *themeSegment = (NSSegmentedControl *)sender;
    
    //Get the current display mode
    [self refreshMainTableview:NO andUpdateFloatingWindow:YES];
    
    PanelController *panelController = [PanelController getPanelControllerInstance];
    
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
    
    [panelController updateTableContent];
    
    [Answers logCustomEventWithName:@"Theme" customAttributes:@{@"themeSelected" : themeSegment.selectedSegment == CLBlackTheme ? @"Black" : @"White"}];

}

- (IBAction)displayModeChanged:(NSSegmentedControl *)modeSegment
{
    ApplicationDelegate *sharedDelegate = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
    
    if (modeSegment.selectedSegment == CLFloatingMode)
    {
        sharedDelegate.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [sharedDelegate.floatingWindow showWindow:nil];
        [sharedDelegate.floatingWindow updateDefaultPreferences];
        [sharedDelegate.floatingWindow startWindowTimer];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        sharedDelegate.floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
        [sharedDelegate.floatingWindow.window close];
        [sharedDelegate.panelController updateDefaultPreferences];
    }
    
    [Answers logCustomEventWithName:@"RelativeDate" customAttributes:@{@"displayMode" : modeSegment.selectedSegment == CLFloatingMode ? @"Floating Mode" : @"Menubar Mode"}];
}


- (IBAction)changeRelativeDayDisplay:(NSSegmentedControl *)relativeDayControl
{
   
    NSNumber *selectedIndex = @(relativeDayControl.selectedSegment);
    
    [Answers logCustomEventWithName:@"RelativeDate" customAttributes:@{@"dayPreference" : selectedIndex.integerValue == 0 ? @"Relative Day" : @"Actual Day"}];
    
    [[NSUserDefaults standardUserDefaults] setObject:selectedIndex forKey:CLRelativeDateKey];
    
    [self refreshMainTableview:YES andUpdateFloatingWindow:YES];
}


- (void)refreshMainTableview:(BOOL)panel andUpdateFloatingWindow:(BOOL)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (panel)
        {
            ApplicationDelegate *appDelegate = (ApplicationDelegate *)[NSApplication sharedApplication].delegate;
            
            PanelController *panelController = [PanelController getPanelControllerInstance];
            
            [panelController updateDefaultPreferences];
            
            [panelController.futureSlider setNeedsDisplay:YES];
            
            [panelController updateTableContent];
            
            [appDelegate.menubarController setUpTimerForUpdatingMenubar];
        }
        
        if (value)
        {
            //Get the current display mode
            NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
            
            if (displayMode.integerValue == CLFloatingMode)
            {
    
                CLFloatingWindowController *floatingWindowInstance = [CLFloatingWindowController sharedFloatingWindow];
                
                [floatingWindowInstance updateTableContent];
                
                [floatingWindowInstance.futureSlider setNeedsDisplay:YES];
                //Only one instance where we need to update panel color and in that instance we pass panel as NO
                
                if (!panel)
                {
                    [floatingWindowInstance updatePanelColor];
                }
            }
        }
    });
}

- (IBAction)showFutureSlider:(id)sender
{
    //Get the current display mode
    [self refreshMainTableview:NO andUpdateFloatingWindow:YES];
}

- (IBAction)showSunriseSunset:(NSSegmentedControl *)sender {
    
    [Answers logCustomEventWithName:@"Sunrise Sunset" customAttributes:@{@"Is It Displayed" : sender.selectedSegment == 0 ? @"YES" : @"NO"}];
    
}
- (IBAction)displayTimeWithSeconds:(NSSegmentedControl *)sender {
    
    [Answers logCustomEventWithName:@"Display Time With Seconds" customAttributes:@{@"Displayed" : sender.selectedSegment == 0 ? @"YES" : @"NO"}];
}

- (IBAction)flashTheTimeSeperators:(NSSegmentedControl *)sender {
    [Answers logCustomEventWithName:@"Flashing Time Seperators" customAttributes:@{@"Displayed" : sender.selectedSegment == 0 ? @"YES" : @"NO"}];
}

@end
