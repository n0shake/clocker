//
//  CLOneWindowController.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import <Cocoa/Cocoa.h>
#import "CLPreferencesViewController.h"
#import "CLAboutUsViewController.h"
#import "CLAppearanceViewController.h"

@interface CLOneWindowController : NSWindowController
@property (strong, nonatomic) CLPreferencesViewController *preferencesView;
+ (instancetype)sharedWindow;

@end
