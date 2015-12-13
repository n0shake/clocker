//
//  CLTimezoneCellView.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/13/15.
//
//

#import <Cocoa/Cocoa.h>

@interface CLTimezoneCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *customName;
@property (weak) IBOutlet NSTextField *relativeDate;
@property (weak) IBOutlet NSTextField *time;
@property (nonatomic) NSInteger rowNumber;
- (void)updateFontFamilyWithFontName:(NSString *)fontName andCell:(CLTimezoneCellView*)cell;

@end
