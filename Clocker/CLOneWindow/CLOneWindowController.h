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

@interface CLOneWindowController : NSWindowController

@property (strong, nonatomic) CLPreferencesViewController *preferencesView;
@property (strong, nonatomic) CLAboutUsViewController *aboutUsView;

+ (instancetype)sharedWindow;

@end
