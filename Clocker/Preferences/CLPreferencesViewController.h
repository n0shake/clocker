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

@property (strong, nonatomic) NSMutableArray *selectedTimeZones;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (atomic, assign) BOOL launchOnLogin;

@property (atomic, strong) NSArray *themes;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

- (void)refereshTimezoneTableView;

@end
