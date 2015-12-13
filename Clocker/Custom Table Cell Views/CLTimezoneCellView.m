//
//  CLTimezoneCellView.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/13/15.
//
//

#import "CLTimezoneCellView.h"
#import "PanelController.h"
#import "CommonStrings.h"

@implementation CLTimezoneCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)labelDidChange:(id)sender
{
    NSTextField *customLabelCell = (NSTextField*) sender;
    PanelController *panelController = (PanelController *)[[[NSApplication sharedApplication] mainWindow] windowController];
    
    NSString *originalValue = customLabelCell.stringValue;
    NSString *customLabelValue = [originalValue stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
   

        if ([[sender superview] isKindOfClass:[self class]]) {
            CLTimezoneCellView *cellView = (CLTimezoneCellView *)[sender superview];
            NSDictionary *timezoneDictionary = panelController.defaultPreferences[cellView.rowNumber];
            NSDictionary *mutableTimeZoneDict = [timezoneDictionary mutableCopy];
        
            (customLabelValue.length > 0) ?    [mutableTimeZoneDict setValue:customLabelValue forKey:CLCustomLabel] : [mutableTimeZoneDict setValue:CLEmptyString forKey:CLCustomLabel]  ;
                [panelController.defaultPreferences replaceObjectAtIndex:cellView.rowNumber withObject:mutableTimeZoneDict];
                [[NSUserDefaults standardUserDefaults] setObject:panelController.defaultPreferences forKey:CLDefaultPreferenceKey];
                
                [panelController updateDefaultPreferences];
                [panelController.mainTableview reloadData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CLCustomLabelChangedNotification object:nil];
        
    }
}

@end
