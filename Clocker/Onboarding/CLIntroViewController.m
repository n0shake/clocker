//
//  CLIntroViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 1/19/16.
//
//

#import "CLIntroViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ApplicationDelegate.h"


@interface CLIntroViewController ()
@property (weak) IBOutlet NSImageView *onboardingImageView;

@end

@implementation CLIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
//     self.view.window.titleVisibility = NSWindowTitleHidden;
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];
    
    self.view.window.styleMask = NSFullSizeContentViewWindowMask;
}

- (IBAction)continueOnboarding:(NSButton *)sender
{
    if ([sender.title isEqualToString:@"Get Started"])
    {
        [self.view.window close];
        ApplicationDelegate *delegate = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
        [delegate togglePanel:nil];
         return;
    }
    
    self.onboardingImageView.image = [NSImage imageNamed:@"FinalOnboarding"];
    [sender setTitle:@"Get Started"];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 1.0f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionMoveIn;
    [self.view setWantsLayer:YES];
    
    [self.onboardingImageView.layer addAnimation:transition forKey:nil];
    
}


@end
