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
#import <pop/POP.h>
#import "CLAnimatedImages.h"

@interface CLIntroViewController ()
@property (weak) IBOutlet NSImageView *onboardingImageView;
@property (weak) IBOutlet CLAnimatedImages *customView;

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
    
    [self.customView addUntitled1Animation];
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
    CALayer *layer = self.onboardingImageView.layer;
    [layer pop_removeAllAnimations];
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    anim.fromValue = @(300);
    anim.toValue = @(100);
    anim.springBounciness = 20.0f;
    
    [layer pop_addAnimation:anim forKey:@"size"];
    
}

- (IBAction)leftAction:(id)sender
{
    [self.customView addUntitled1Animation];
}

- (IBAction)rightAction:(id)sender
{
    
}


@end
