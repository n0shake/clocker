//
//  CLParentPanelController.h
//  Clocker
//
//  Created by Abhishek Banthia on 4/4/16.
//
//

#import <Cocoa/Cocoa.h>
#import "CLOneWindowController.h"
#import "CLAppFeedbackWindowController.h"

@interface CLParentPanelController : NSWindowController<NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>


@property (nonatomic, strong) NSMutableArray *defaultPreferences;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) NSInteger futureSliderValue;
@property (nonatomic) BOOL showReviewCell;

@property (weak) IBOutlet NSStackView *stackView;
@property (weak) IBOutlet NSView *reviewView;
@property (weak) IBOutlet NSView *futureSliderView;
@property (weak) IBOutlet NSButton *shutdownButton;
@property (weak) IBOutlet NSButton *preferencesButton;
@property (weak) IBOutlet NSSlider *futureSlider;
@property (weak) IBOutlet NSTableView *mainTableview;
@property (weak) IBOutlet NSLayoutConstraint *scrollViewHeight;
@property (nonatomic, strong) CLOneWindowController *oneWindow;

@property (weak, nonatomic) IBOutlet NSImageView *imageView;
@property (weak, nonatomic) IBOutlet NSTextField *leftField;
@property (weak, nonatomic) IBOutlet NSButton *leftButton;
@property (weak, nonatomic) IBOutlet NSButton *rightButton;
@property (strong, nonatomic) CLAppFeedbackWindowController *feedbackWindow;

- (void)updateDefaultPreferences;
- (void)showOptions:(BOOL)value;
- (void)removeContextHelpForSlider;
- (void)updatePanelColor;
- (void)openPreferenceWindowWithValue:(BOOL)value;
- (void)updateTableContent;

@end
