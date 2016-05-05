//
//  CLPausableTimer.h
//  Clocker
//
//  Created by Abhishek Banthia on 5/4/16.
//
//

#import <Foundation/Foundation.h>

@interface CLPausableTimer : NSObject

//Timer Info
@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;
@property (nonatomic) id userInfo;
@property (nonatomic) BOOL repeats;

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) BOOL isPaused;

+(CLPausableTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;

-(void)pause;
-(void)start;

@end
