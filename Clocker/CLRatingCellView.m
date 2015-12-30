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
#import "CLAppFeedbackWindowController.h"

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
        PanelController *panelRef = [[[NSApplication sharedApplication] mainWindow] windowController];
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
    PanelController *panelRef = [[[NSApplication sharedApplication] mainWindow] windowController];
    panelRef.showReviewCell = NO;
    [panelRef updateDefaultPreferences];
}

- (void) setAnimatedStringValue:(NSString *)aString
                   andTextField:(NSTextField *)textfield
            withLeftButtonTitle:(NSString *)leftTitle
            andRightButtonTitle:(NSString *)rightTitle
{
    if ([[textfield stringValue] isEqual: aString])
    {
        return;
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration: 1.0];
        [context setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
        [self.imageView.animator setAlphaValue:0.0];
        [self.leftButton.animator setAlphaValue:0.0];
        [self.rightButton.animator setAlphaValue:0.0];
        [textfield.animator setAlphaValue: 0.0];
    }
                        completionHandler:^{
                            [textfield setStringValue: aString];
                            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                                [context setDuration: 1.0];
                                [context setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];
                                [self.imageView.animator setAlphaValue: 1.0];
                                [textfield.animator setAlphaValue: 1.0];
                                [self.leftButton.animator setAlphaValue:1.0];
                                [self.rightButton.animator setAlphaValue:1.0];
                                if ([self.leftButton.title isEqualToString:@"Not Really"]) {
                                    [self.leftButton.animator setTitle:CLNoThanksTitle];
                                }
                                if ([self.rightButton.title isEqualToString:CLYesWithExclamation]) {
                                    [self.rightButton.animator setTitle:@"Yes, sure"];
                                }
                                
                                [self.leftButton.animator setTitle:leftTitle];
                                 [self.rightButton.animator setTitle:rightTitle];

                            } completionHandler: ^{
                                                            }];
                        }];
}


@end
