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
@property (weak) IBOutlet NSTextField *sunriseSetTime;
@property (weak) IBOutlet NSImageView *sunriseSetImage;
@property (nonatomic, assign) NSInteger rowNumber;

- (void)setTextColor:(NSColor *)color;
- (void)setUpLayout;

@end

