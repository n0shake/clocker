//
//  CLPreferencesViewController.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey+ShortcutRecorder.h>
#import "CLParentViewController.h"

typedef NS_ENUM(NSUInteger, CLTheme) {
    CLDefaultTheme,
    CLBlackTheme
};

@interface CLPreferencesViewController : CLParentViewController<SRRecorderControlDelegate>

- (void)refereshTimezoneTableView;
- (IBAction)addTimeZone:(id)sender;

@end
