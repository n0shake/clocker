//
//  CLPreferencesViewController.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    CLDefaultTheme,
    CLBlackTheme
} CLTheme;

@interface CLPreferencesViewController : NSViewController



- (void)refereshTimezoneTableView;

@end
