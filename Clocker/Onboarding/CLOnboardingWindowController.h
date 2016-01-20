//
//  CLOnboardingWindowController.h
//  Clocker
//
//  Created by Abhishek Banthia on 1/19/16.
//
//

#import <Cocoa/Cocoa.h>
#import "CLIntroViewController.h"

@interface CLOnboardingWindowController : NSWindowController

@property (strong, nonatomic) CLIntroViewController *introViewController;

+ (instancetype)sharedWindow;

@end
