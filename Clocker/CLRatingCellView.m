//
//  CLRatingCellView.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/11/15.
//
//

#import "CLRatingCellView.h"
#import "iRate.h"
#import <QuartzCore/QuartzCore.h>
#import "PanelController.h"

@implementation CLRatingCellView

NSString *const CLNotReallyButtonTitle = @"Not Really";
NSString *const CLFeedbackString = @"Mind giving feedback?";
NSString *const CLNoThanksTitle = @"No, thanks";
NSString *const CLYesWithQuestionMark = @"Yes?";
NSString *const CLYesWithExclamation = @"Yes!";



- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
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
        //Make the row disappear and call remind later
        PanelController *panelRef = [PanelController getPanelControllerInstance];
        panelRef.showReviewCell = NO;
        [panelRef updateDefaultPreferences];
        [panelRef closePanel];
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
        [self updateMainTableView];
        self.feedbackWindow = [CLAppFeedbackWindowController sharedWindow];
        [self.feedbackWindow showWindow:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        [[iRate sharedInstance] rate];
        [self updateMainTableView];
    }
}

- (void)updateMainTableView
{
    PanelController *panelRef = [PanelController getPanelControllerInstance];
    panelRef.showReviewCell = NO;
    [panelRef updateDefaultPreferences];
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
