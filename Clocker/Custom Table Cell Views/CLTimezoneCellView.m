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
#import "CLTimezoneData.h"

@implementation CLTimezoneCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)labelDidChange:(id)sender
{
    NSTextField *customLabelCell = (NSTextField*) sender;
    __block PanelController *panelController;
    
    [[[NSApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([window.windowController isMemberOfClass:[PanelController class]])
        {
            panelController = window.windowController;
        }
    }];
    
    NSString *originalValue = customLabelCell.stringValue;
    NSString *customLabelValue = [originalValue stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
    
    
    if ([[sender superview] isKindOfClass:[self class]]) {
        CLTimezoneCellView *cellView = (CLTimezoneCellView *)[sender superview];
        NSData *dataObject = panelController.defaultPreferences[cellView.rowNumber];
        CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:dataObject];
        
        [panelController.defaultPreferences enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CLTimezoneData *timeObject = [CLTimezoneData getCustomObject:object];
            if ([timeObject.formattedAddress isEqualToString:customLabelValue]) {
                timeObject.customLabel = CLEmptyString;
            }
            
            
        }];
        
        timezoneObject.customLabel = (customLabelValue.length > 0) ? customLabelValue : CLEmptyString;
        
        if ([timezoneObject.isFavourite isEqualToNumber:@1])
        {
            NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:timezoneObject];
            [[NSUserDefaults standardUserDefaults] setObject:encodedObject
                                                      forKey:@"favouriteTimezone"];
        }

        NSData *newObject = [NSKeyedArchiver archivedDataWithRootObject:timezoneObject];
        [panelController.defaultPreferences replaceObjectAtIndex:cellView.rowNumber withObject:newObject];
        [[NSUserDefaults standardUserDefaults] setObject:panelController.defaultPreferences forKey:CLDefaultPreferenceKey];
        
        [panelController updateDefaultPreferences];
        [panelController.mainTableview reloadData];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:CLCustomLabelChangedNotification
         object:nil];
        
    }
}

- (void)updateTextColorWithColor:(NSColor *)color andCell:(CLTimezoneCellView*)cell
{
    cell.relativeDate.textColor = color;
    cell.customName.textColor = color;
    cell.time.textColor = color;
}

- (void)setUpAutoLayoutWithCell:(CLTimezoneCellView *)cell
{
    CGFloat width = [cell.relativeDate.stringValue
                     sizeWithAttributes: @{NSFontAttributeName:cell.relativeDate.font}].width;
    
    
    [cell.relativeDate.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        if (constraint.constant > 20)
        {
            constraint.constant = width+8;
        }
        
        
    }];
}

@end
