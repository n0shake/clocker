//
//  CLOnboardingWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 1/19/16.
//
//

#import "CLOnboardingWindowController.h"
#import <QuartzCore/QuartzCore.h>
#import <pop/POP.h>


@interface CLOnboardingWindowController ()

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSButton *continueButtonOutlet;
@property (strong, nonatomic) CLIntroViewController *introViewController;

@end

static CLOnboardingWindowController *sharedOnboardingWindow;

@implementation CLOnboardingWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.backgroundColor = [NSColor whiteColor];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedWindow
{
    if (sharedOnboardingWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedOnboardingWindow = [[self alloc] initWithWindowNibName:@"CLOnboardingWindow"];
            
        });
    }
    
    return sharedOnboardingWindow;
}

- (IBAction)continueButtonPressed:(id)sender
{
    self.introViewController = [[CLIntroViewController alloc]
                                initWithNibName:@"CLIntroView" bundle:nil];
    
    CGRect oldFrame = self.window.frame;
    CGRect newFrame = self.introViewController.view.frame;
    
    [self performBoundsAnimationWithOldRect:oldFrame andNewRect:newFrame];


}

- (void)performBoundsAnimationWithOldRect:(CGRect)fromRect andNewRect:(CGRect)newRect
{
    

    
    [self.window setFrame:fromRect display:NO animate:NO];
    
    self.window.contentView.wantsLayer = YES;
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewBounds];
    
    anim.toValue = [NSValue valueWithCGRect:newRect];
    
    anim.springSpeed = 1;
    
    [self.window.contentView.layer pop_addAnimation:anim forKey:@"popBounds"];
    
    [self.window setContentSize:self.introViewController.view.frame.size];
    
    [self.window setContentView:self.introViewController.view];
}



@end
