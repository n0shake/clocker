//
//  CLTableViewDataSource.h
//  Clocker
//
//  Created by Abhishek Banthia on 7/25/16.
//
//

#import <Foundation/Foundation.h>

@interface CLTableViewDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) BOOL showReviewCell;
@property (assign) NSInteger futureSliderValue;

- (instancetype)initWithItems:(NSArray *)objects;

@end
