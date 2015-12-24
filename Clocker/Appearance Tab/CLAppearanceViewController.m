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
    
    
    //Certain fonts don't look good with constraints set
    NSMutableArray *availableFonts = [[NSMutableArray alloc] init];
    
    NSFontCollection *fontCollection = [NSFontCollection fontCollectionWithName:@"com.apple.UserFonts"];
    
    for (NSFontDescriptor *descriptor in fontCollection.matchingDescriptors) {
        if ([descriptor objectForKey:@"NSFontFamilyAttribute"]) {
            if (![availableFonts containsObject:[descriptor objectForKey:@"NSFontFamilyAttribute"]]) {
                [availableFonts addObject:[descriptor objectForKey:@"NSFontFamilyAttribute"]];
            }
        }
    }
    NSArray *fontsToRemove = [NSArray arrayWithObjects:@"Apple Chancery", @"Zapfino",
                              @"Trattatello", @"Noteworthy", @"Arial Black", @"Chalkduster",@"Monoid", @"Andale Mono", @"Courier" ,@"Courier New",@"Geneva",@"Menlo", @"Monaco",@"PT Mono", @"Verdana", nil];
    for (NSString *font in fontsToRemove) {
        if([availableFonts containsObject:font])
        {
            [availableFonts removeObject:font];
        }
    }
    
    [availableFonts insertObject:@"Default" atIndex:0];
    self.fontFamilies = [[NSArray alloc] initWithArray:availableFonts];
    // Do view setup here.
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
    
    [panelController.mainTableview reloadData];

}

- (IBAction)changeRelativeDayDisplay:(id)sender
{
    NSSegmentedControl *relativeDayControl = (NSSegmentedControl*) sender;
    NSNumber *selectedIndex = [NSNumber numberWithInteger:relativeDayControl.selectedSegment];
    [[NSUserDefaults standardUserDefaults] setObject:selectedIndex forKey:@"relativeDate"];
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
