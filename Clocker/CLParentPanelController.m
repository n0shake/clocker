//
//  CLParentPanelController.m
//  Clocker
//
//  Created by Abhishek Banthia on 4/4/16.
//
//

#import "CLParentPanelController.h"
#import "CLTimezoneData.h"
#import "CommonStrings.h"
#import "CLOneWindowController.h"
#import <pop/POP.h>
#import "iRate.h"
#import "CLTableViewDataSource.h"
#import <Crashlytics/Crashlytics.h>

NSString *const CLNotReallyButtonTitle = @"Not Really";
NSString *const CLFeedbackString = @"Mind giving feedback?";
NSString *const CLNoThanksTitle = @"No, thanks";
NSString *const CLYesWithQuestionMark = @"Yes?";
NSString *const CLYesWithExclamation = @"Yes!";

@interface CLParentPanelController ()
@property (strong) CLTableViewDataSource *timezoneDataSource;
@end

@implementation CLParentPanelController

- (void)awakeFromNib
{
     [super awakeFromNib];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey] isKindOfClass:[NSString class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLThemeKey];
    }
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
    }
    
    self.mainTableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CLDisplayFutureSliderKey options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CLUserFontSizePreference options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CLThemeKey options:NSKeyValueObservingOptionNew context:nil];
    [self updateReviewViewFontColor];
    
    self.futureSliderView.wantsLayer = YES;
    self.reviewView.wantsLayer = YES;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:CLDisplayFutureSliderKey]) {
        
        if ([change[@"new"] isKindOfClass:[NSNumber class]])
        {
            self.futureSlider.hidden = [change[@"new"] isEqualToNumber:@(1)] ? YES : NO;
            [Answers logCustomEventWithName:@"Is Future Slider Displayed" customAttributes:@{@"Display Value" : self.futureSlider.isHidden ? @"NO" : @"YES"}];
        }

    }
    else if([keyPath isEqualToString:CLUserFontSizePreference])
    {
        NSNumber *userFontSize = [[NSUserDefaults standardUserDefaults] objectForKey:CLUserFontSizePreference];
        [Answers logCustomEventWithName:@"User Font Size Preference" customAttributes:@{@"Font Size" : userFontSize}];
        self.scrollViewHeight.constant = self.defaultPreferences.count * (self.mainTableview.rowHeight + userFontSize.integerValue*1.5);
        
        if (self.scrollViewHeight.constant > [self getScreenHeight] - 100)
        {
            self.scrollViewHeight.constant = [self getScreenHeight] - 100;
        }
        
        [self.mainTableview reloadData];
        
    }
    else if([keyPath isEqualToString:CLThemeKey])
    {
        [self updateReviewViewFontColor];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (CGFloat)getScreenHeight
{
    NSRect frame = [[NSScreen mainScreen] frame];
    return frame.size.height;
}

- (void)updateReviewViewFontColor
{
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (theme.integerValue == 0) {
        self.leftField.textColor = [NSColor blackColor];
        self.futureSliderView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
    else
    {
        self.futureSliderView.layer.backgroundColor = [NSColor blackColor].CGColor;
        self.leftField.textColor = [NSColor whiteColor];
    }
}

- (void) updateDefaultPreferences
{
    NSArray *defaultZones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
    
    self.defaultPreferences = self.defaultPreferences == nil ? [[NSMutableArray alloc] initWithArray:defaultZones] : [NSMutableArray arrayWithArray:defaultZones];
    
    NSNumber *userFontSize = [[NSUserDefaults standardUserDefaults] objectForKey:CLUserFontSizePreference];
    
    self.scrollViewHeight.constant = self.defaultPreferences.count * (self.mainTableview.rowHeight + userFontSize.integerValue*1.5);
    
    if (self.scrollViewHeight.constant > [self getScreenHeight] - 100)
    {
        self.scrollViewHeight.constant = [self getScreenHeight] - 100;
    }
    
    [self updatePanelColor];
    
    if (!self.timezoneDataSource) {
        self.timezoneDataSource = [[CLTableViewDataSource alloc] initWithItems:self.defaultPreferences];
        self.mainTableview.dataSource = self.timezoneDataSource;
        self.mainTableview.delegate = self.timezoneDataSource;
    }
    
    self.timezoneDataSource.timezoneObjects = self.defaultPreferences;
    self.timezoneDataSource.futureSliderValue = self.futureSliderValue;
}

- (void)dealloc
{
    self.timezoneDataSource = nil;
}

- (void)updatePanelColor
{
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    if (theme.integerValue == 1)
    {
        (self.mainTableview).backgroundColor = [NSColor blackColor];
        self.window.alphaValue = 1;
    }
    else
    {
        (self.mainTableview).backgroundColor = [NSColor whiteColor];
        self.window.alphaValue = 1;
    }
}

- (IBAction)sliderMoved:(id)sender
{
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *newDate = [currentCalendar dateByAddingUnit:NSCalendarUnitMinute
                                                  value:self.futureSliderValue
                                                 toDate:[NSDate date]
                                                options:kNilOptions];
    
    self.dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    self.dateFormatter.timeStyle = kCFDateFormatterShortStyle;
    
    NSString *relativeDate = [currentCalendar isDateInToday:newDate] ? @"Today" : @"Tomorrow";
    
    NSString *helper = [self.dateFormatter stringFromDate:newDate];
    
    NSHelpManager *helpManager = [NSHelpManager sharedHelpManager];
    
    NSPoint pointInScreen = [NSEvent mouseLocation];
    pointInScreen.y -= 5;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", relativeDate, helper]];
    [NSHelpManager setContextHelpModeActive:YES];
    [helpManager setContextHelp:attributedString forObject:self.futureSlider];
    [helpManager showContextHelpForObject:self.futureSlider locationHint:pointInScreen];
    
    self.timezoneDataSource.futureSliderValue = self.futureSliderValue;
    
    [self.mainTableview reloadData];
}

- (void)removeContextHelpForSlider
{
    NSEvent *newEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                           location:self.window.mouseLocationOutsideOfEventStream
                                      modifierFlags:0
                                          timestamp:0
                                       windowNumber:self.window.windowNumber
                                            context:self.window.graphicsContext
                                        eventNumber:0
                                         clickCount:1
                                           pressure:0];
    [NSApp postEvent:newEvent atStart:NO];
    newEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
                                  location:self.window.mouseLocationOutsideOfEventStream
                             modifierFlags:0
                                 timestamp:0
                              windowNumber:self.window.windowNumber
                                   context:self.window.graphicsContext
                               eventNumber:0
                                clickCount:1
                                  pressure:0];
    
    [NSApp postEvent:newEvent atStart:NO];
}

#pragma mark -
#pragma mark Preferences Target-Action
#pragma mark -

- (IBAction)openPreferences:(id)sender
{
    [self openPreferenceWindowWithValue:NO];
}

- (void)openPreferenceWindowWithValue:(BOOL)value
{
    self.oneWindow = [CLOneWindowController sharedWindow];
    
    [self.oneWindow showWindow:nil];
    
    CGRect originalFrame = self.oneWindow.window.frame;
    
    CGRect oldFrame = CGRectMake(self.oneWindow.window.frame.origin.x, 730,self.oneWindow.window.frame.size.width, self.oneWindow.window.frame.size.height);
    
    [self performBoundsAnimationWithOldRect:oldFrame andNewRect:originalFrame andShouldOpenTimezonePanel:value];
    
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)performBoundsAnimationWithOldRect:(CGRect)fromRect andNewRect:(CGRect)newRect andShouldOpenTimezonePanel:(BOOL)shouldOpen
{
    [self.oneWindow.window setFrame:fromRect display:NO animate:NO];
    
    self.window.contentView.wantsLayer = YES;
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPWindowFrame];
    anim.toValue = [NSValue valueWithCGRect:newRect];
    anim.springSpeed = 1;
    [self.oneWindow.window pop_addAnimation:anim forKey:@"popBounds"];
    
    anim.completionBlock = ^(POPAnimation *animation, BOOL finished)
    {
        if (finished && shouldOpen)
        {
            [self.oneWindow.preferencesView addTimeZone:self];
        }
    };
}

- (void)updateTableContent
{
    [self.mainTableview reloadData];
}

- (IBAction)actionOnNegativeFeedback:(id)sender
{
    NSButton *leftButton = (NSButton *)sender;
    
    if ([leftButton.title isEqualToString:CLNotReallyButtonTitle]) {
        [self setAnimatedStringValue:CLFeedbackString
                        andTextField:self.leftField
                 withLeftButtonTitle:CLNoThanksTitle
                 andRightButtonTitle:CLYesWithQuestionMark];
    }
    else
    {
        [self updateReviewView];
        [[iRate sharedInstance] remindLater];
    }
}

- (IBAction)actionOnPositiveFeedback:(id)sender
{
    NSButton *rightButton = (NSButton *)sender;
    
    if ([rightButton.title isEqualToString:CLYesWithExclamation]) {
        [self setAnimatedStringValue:@"Mind rating us?"
                        andTextField:self.leftField
                 withLeftButtonTitle:CLNoThanksTitle
                 andRightButtonTitle:@"Yes"];
    }
    else if ([rightButton.title isEqualToString:CLYesWithQuestionMark])
    {
        [self updateReviewView];
        self.feedbackWindow = [CLAppFeedbackWindowController sharedWindow];
        [self.feedbackWindow showWindow:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        [[iRate sharedInstance] rate];
        [self updateReviewView];
    }
}

- (void)updateReviewView
{
    self.reviewView.hidden = YES;
    self.showReviewCell = NO;
    self.leftField.stringValue = @"Enjoy using Clocker?";
    self.leftButton.title = @"Not Really";
    self.rightButton.title = @"Yes!";
}

- (void) setAnimatedStringValue:(NSString *)aString
                   andTextField:(NSTextField *)textfield
            withLeftButtonTitle:(NSString *)leftTitle
            andRightButtonTitle:(NSString *)rightTitle
{
    if ([textfield.stringValue isEqual: aString])
    {
        return;
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 1.0;
        context.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
        (self.imageView.animator).alphaValue = 0.0;
        (self.leftButton.animator).alphaValue = 0.0;
        (self.rightButton.animator).alphaValue = 0.0;
        (textfield.animator).alphaValue = 0.0;
    }
                        completionHandler:^{
                            textfield.stringValue = aString;
                            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                                context.duration = 1.0;
                                context.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
                                (self.imageView.animator).alphaValue = 1.0;
                                (textfield.animator).alphaValue = 1.0;
                                (self.leftButton.animator).alphaValue = 1.0;
                                (self.rightButton.animator).alphaValue = 1.0;
                                if ([self.leftButton.title isEqualToString:@"Not Really"]) {
                                    (self.leftButton.animator).title = CLNoThanksTitle;
                                }
                                if ([self.rightButton.title isEqualToString:CLYesWithExclamation]) {
                                    (self.rightButton.animator).title = @"Yes, sure";
                                }
                                
                                (self.leftButton.animator).title = leftTitle;
                                (self.rightButton.animator).title = rightTitle;
                                
                            } completionHandler: ^{
                            }];
                        }];
}



@end
