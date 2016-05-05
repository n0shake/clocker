//
//  CLTimezoneCellView.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/13/15.
//
//

#import <Cocoa/Cocoa.h>

@interface CLTimezoneCellView : NSTableCellView<NSTextDelegate>

@property (weak) IBOutlet NSTextField *customName;
@property (weak) IBOutlet NSTextField *relativeDate;
@property (weak) IBOutlet NSTextField *time;
@property (nonatomic, assign) NSInteger rowNumber;

- (void)updateTextColorWithColor:(NSColor *)color andCell:(CLTimezoneCellView*)cell;
- (void)setUpAutoLayoutWithCell:(CLTimezoneCellView *)cell;

@end

