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

typedef enum : NSUInteger {
    CLDefaultTheme,
    CLBlackTheme
} CLTheme;

@interface CLPreferencesViewController : NSViewController<SRRecorderControlDelegate>



- (void)refereshTimezoneTableView;
- (IBAction)addTimeZone:(id)sender;

@end
