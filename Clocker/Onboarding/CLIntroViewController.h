//
//  CLIntroViewController.h
//  Clocker
//
//  Created by Abhishek Banthia on 1/19/16.
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    CLFloatingViewFeature,
    CLKeyboardShortcutFeature,
    CLFavouriteFeature
} CLFeature;

@interface CLIntroViewController : NSViewController
@end
