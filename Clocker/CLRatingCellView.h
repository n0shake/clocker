//
//  CLRatingCellView.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/11/15.
//
//

#import <Cocoa/Cocoa.h>

@interface CLRatingCellView : NSTableCellView

@property (weak, nonatomic) IBOutlet NSTextField *leftField;
@property (weak, nonatomic) IBOutlet NSButton *leftButton;
@property (weak, nonatomic) IBOutlet NSButton *rightButton;

@end
