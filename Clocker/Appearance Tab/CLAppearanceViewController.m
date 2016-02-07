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

- (NSImage *)imageWithSubviewsWithTextField:(NSTextField *)textField
{
    NSSize mySize = textField.bounds.size;
    NSSize imgSize = NSMakeSize( mySize.width, mySize.height );
    
    NSBitmapImageRep *bir = [textField bitmapImageRepForCachingDisplayInRect:[textField bounds]];
    [bir setSize:imgSize];
    [textField cacheDisplayInRect:[textField bounds] toBitmapImageRep:bir];
    
    NSImage* image = [[NSImage alloc]initWithSize:imgSize];
    [image addRepresentation:bir];
    return image;
    
}

- (NSImage *)textWithTextField:(NSTextField *)textField
{
    NSString *myString = textField.stringValue;
    unsigned char *string = (unsigned char *) [myString UTF8String];
    NSSize mySize = NSMakeSize(50,100); //or measure the string
    
    NSBitmapImageRep *bir = [[NSBitmapImageRep alloc]
                                                        initWithBitmapDataPlanes:&string
                                                        pixelsWide:mySize.width pixelsHigh:mySize.height
                                                        bitsPerSample:8
                                                        samplesPerPixel:3  // or 4 with alpha
                                                        hasAlpha:NO
                                                        isPlanar:NO
                                                        colorSpaceName:NSDeviceRGBColorSpace
                                                        bitmapFormat:0
                                                        bytesPerRow:0  // 0 == determine automatically
                                                        bitsPerPixel:0];  // 0 == determine automatically
    
    //draw text using -(void)drawInRect:(NSRect)aRect withAttributes:(NSDictionary *)attributes
    
    NSImage* image = [[NSImage alloc]initWithSize:mySize];
    [image addRepresentation:bir];
    return image;
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



@end
