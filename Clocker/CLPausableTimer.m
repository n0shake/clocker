//
//  CLPausableTimer.m
//  Clocker
//
//  Created by Abhishek Banthia on 5/4/16.
//
//

#import "CLPausableTimer.h"

@implementation CLPausableTimer

{
    NSDate *cycleStartDate;
    NSTimeInterval remainingInterval;
    BOOL hasPausedThisCycle;
}

+(CLPausableTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    
    CLPausableTimer *new = [[CLPausableTimer alloc] init];
    new.timeInterval = timeInterval;
    new.target = target;
    new.selector = selector;
    new.userInfo = userInfo;
    new.repeats = repeats;
    
    return new;
}

-(void)start
{
    
    [self.timer invalidate];
    
    if(self.isPaused)
    {   //If resuming from a pause, use partial remaining time interval
        self.timer = [NSTimer scheduledTimerWithTimeInterval:remainingInterval target:self selector:@selector(timerFired:) userInfo:self.userInfo repeats:self.repeats];
        
    } else {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval target:self selector:@selector(timerFired:) userInfo:self.userInfo repeats:self.repeats];
        
        remainingInterval = self.timeInterval;
    }
    
    self.isPaused = NO;
    cycleStartDate = [NSDate date];
    
}

-(void)pause
{
    if(self.isPaused) return;
    
    self.isPaused = YES;
    hasPausedThisCycle = YES;
    
    [self.timer invalidate];
    
    //keep track of time left on this cycle
    remainingInterval -= [[NSDate date] timeIntervalSinceDate:cycleStartDate];
}

-(void)timerFired:(NSTimer *)timer
{
    if(self.isPaused) return;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:self];
#pragma clang diagnostic pop
    
    //reset remaining time to original value
    remainingInterval = self.timeInterval;
    cycleStartDate = [NSDate date];
    
    if(hasPausedThisCycle)
    {
        //current timer is running on remainingInterval
        
        //reset pause flag for next cycle
        hasPausedThisCycle = NO;
        
        if(self.repeats)
        {   //need to set up a new timer with original timeInterval
            [self.timer invalidate];
            [self start];
        }
        
    }
}

-(void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
    self.selector = nil;
    self.target = nil;
    self.userInfo = nil;
}

@end
