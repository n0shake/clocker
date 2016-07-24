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
#import "CommonStrings.h"
#import "FloatingView.h"
#import "CLShortcutAnimatedView.h"
#import "CLFavouriteAnimatedView.h"
#import "PanelController.h"

@interface CLIntroViewController ()

@property (weak) IBOutlet NSTextField *headerView;
@property (weak) IBOutlet NSView *customView;
@property (strong) FloatingView *floatingView;
@property (strong) CLShortcutAnimatedView *shortCutView;
@property (strong) CLFavouriteAnimatedView *favouriteView;
@property (strong) NSString *informativeText;
@property (strong) NSArray *headerLabelString;
@property (weak) IBOutlet NSButton *nextActionButton;

@end

@implementation CLIntroViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.headerLabelString = @[@"Now, Clocker stays on top of all the windows", @"Access Clocker through keyboard shortcuts", @"Customize your menubar with Favourites"];
    
    [self.headerView setWantsLayer:YES];
    
    self.view.window.styleMask = NSFullSizeContentViewWindowMask;
    
    [self initializeViews];
    
    self.nextActionButton.hidden = YES;
    
    [self addAnimationInOrderWithTag:CLFloatingViewFeature];
    
}

- (void)initializeViews
{
    self.floatingView = [[FloatingView alloc] initWithFrame:self.customView.frame];
    self.favouriteView = [[CLFavouriteAnimatedView alloc] initWithFrame:self.customView.frame];
    self.shortCutView = [[CLShortcutAnimatedView alloc] initWithFrame:self.customView.frame];
}


- (void)addAnimationInOrderWithTag:(CLFeature)integer
{
    switch (integer) {
        case CLFloatingViewFeature:
            [self showFloatingViewInformation];
            break;
            
        case CLKeyboardShortcutFeature:
            [self showShortcutInformation];
            break;
            
        case CLFavouriteFeature:
            [self showFavouritingAnimation];
            break;
            
        default:
            [self performSkipEvent];
            break;
    }
}

- (void)showFloatingViewInformation
{
    
    self.informativeText = @"Introducing the Floating Mode, now Clocker floats on your screen while you work, play or do whatever you want to.";
    
    [self performOpacityAnimationWithString:self.headerLabelString[0] andAnimationBlock:^{
        
        [self.view replaceSubview:self.customView with:self.floatingView];
        
        [self.floatingView addUntitled1Animation];
        
        [self performContinueButtonAnimationWithValue:NO];
        
    }];
    
    
}

- (void)performContinueButtonAnimationWithValue:(BOOL)value
{
    self.nextActionButton.hidden = value;
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlphaValue];
    anim.springBounciness = 8;
    anim.springSpeed = 4;
    anim.toValue = @(1.0);
    anim.beginTime = CACurrentMediaTime()+0.1*1;
    [self.nextActionButton pop_addAnimation:anim forKey:@"appear"];
}

- (void)showShortcutInformation
{
    
    self.floatingView.hidden = YES;
    
    self.informativeText = @"No need to click on the Clocker icon. Set a keyboard shortcut and hit the keys.";
    
    [self performOpacityAnimationWithString:self.headerLabelString[1] andAnimationBlock:^{
        
        self.floatingView.hidden = NO;
        
        [self.view replaceSubview:self.floatingView with:self.shortCutView];
        
        [self.shortCutView addScaleAnimationAnimation];
        
        [self performContinueButtonAnimationWithValue:NO];
        
    }];

}

- (void)showFavouritingAnimation
{
    
    self.shortCutView.hidden = YES;
    
    self.informativeText = @"Favourite a city and now the menubar will display the time of the place. Customize what you want to see in the menubar. Totally upto you!";
    
    [self performOpacityAnimationWithString:self.headerLabelString[2] andAnimationBlock:^{
        
        self.shortCutView.hidden = NO;
        
        [self.view replaceSubview:self.shortCutView with:self.favouriteView];
        
        [self.favouriteView addUntitled1Animation];
        
        [self performContinueButtonAnimationWithValue:NO];
        
    }];
}

- (IBAction)continueOnboarding:(NSButton *)sender
{
    
    if ([sender.title isEqualToString:@"Continue"])
    {
        [self performContinueButtonAnimationWithValue:YES];
        
        [self addAnimationInOrderWithTag:CLKeyboardShortcutFeature];
        
        sender.title = @"Next";
    }
    else if ([sender.title isEqualToString:@"Next"])
    {
       [self performContinueButtonAnimationWithValue:YES];
        
       [self addAnimationInOrderWithTag:CLFavouriteFeature];
        
        sender.title = @"Get Started";
    }
    else
    {
        /*First check if there are any timezones/cities added
        
         If not, open the Preferences window
         
        */
        
        NSArray *addedTimezones = [[NSUserDefaults standardUserDefaults] objectForKey:CLDefaultPreferenceKey];
        
        addedTimezones.count == 0 ? [self openPreferences] : [self performSkipEvent];
        
        [self.view.window close];
        
    }
    
}

- (void)performOpacityAnimationWithString:(NSString *)string andAnimationBlock:(void(^)(void))animationBlock
{
    
    self.headerView.stringValue = string;
    
    POPSpringAnimation *scale = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scale.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
    scale.springBounciness = 20.f;
    
    [self.headerView.layer pop_addAnimation:scale forKey:@"scale"];
    
    scale.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        // Shrink animation done
        
        if (finished)
        {
            animationBlock();
        }
        
        
    };
}

- (IBAction)skipOnboarding:(id)sender
{
    [self performSkipEvent];
}

- (void) performSkipEvent
{
    [self.view.window close];
    
    ApplicationDelegate *delegate = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
    
    [delegate togglePanel:nil];
}

- (void)openPreferences
{
    ApplicationDelegate *delegate = (ApplicationDelegate*)[NSApplication sharedApplication].delegate;
    
    [delegate.panelController openPreferenceWindowWithValue:YES];
}

@end
