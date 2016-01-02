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

@interface CLAppearanceViewController ()
@property (weak) IBOutlet NSSegmentedControl *timeFormat;
@property (weak) IBOutlet NSSegmentedControl *theme;

@end

@implementation CLAppearanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];
    
}

- (IBAction)timeFormatSelectionChanged:(id)sender
{
    NSSegmentedControl *timeFormat = (NSSegmentedControl *)sender;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:timeFormat.selectedSegment] forKey:CL24hourFormatSelectedKey];
    
    [self refreshMainTableview];
}

- (IBAction)themeChanged:(id)sender
{
    NSSegmentedControl *themeSegment = (NSSegmentedControl *)sender;
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

- (IBAction)changeRelativeDayDisplay:(id)sender
{
    NSSegmentedControl *relativeDayControl = (NSSegmentedControl*) sender;
    NSNumber *selectedIndex = [NSNumber numberWithInteger:relativeDayControl.selectedSegment];
    [[NSUserDefaults standardUserDefaults] setObject:selectedIndex forKey:CLRelativeDateKey];
    [self refreshMainTableview];
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

@end
