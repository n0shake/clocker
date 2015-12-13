//
//  CLPreferencesViewController.h
//  Clocker
//
//  Created by Abhishek Banthia on 12/12/15.
//
//

#import <Cocoa/Cocoa.h>

@interface CLPreferencesViewController : NSViewController

@property (strong, nonatomic) NSMutableArray *timeZoneArray;
@property (strong, nonatomic) NSMutableArray *selectedTimeZones;
@property (strong, nonatomic) NSArray *filteredArray;
@property (atomic, assign) BOOL launchOnLogin;
@property (atomic, strong) NSArray *fontFamilies;
@property (atomic, strong) NSArray *themes;

@end
