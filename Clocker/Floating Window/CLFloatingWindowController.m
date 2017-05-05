//
//  CLFloatingWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 4/2/16.
//
//

#import "CLFloatingWindowController.h"
#import "CommonStrings.h"
#import "CLOneWindowController.h"

@interface CLFloatingWindowController ()

@end

static CLFloatingWindowController *sharedFloatingWindow = nil;
NSString *const CLTimezoneCellIdentifier = @"timeZoneCell";

@interface CLFloatingWindowController()

@end

@implementation CLFloatingWindowController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.futureSlider.continuous = YES;
    
    if (!self.dateFormatter)
    {
        self.dateFormatter = [NSDateFormatter new];
        self.dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey] isKindOfClass:[NSString class]]){
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:CLThemeKey];
    }
    
    NSPanel *panel = (id)self.window;
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
  
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
        self.window.backgroundColor = [NSColor blackColor];
        panel.backgroundColor = [NSColor blackColor];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
        self.window.backgroundColor = [NSColor whiteColor];
        panel.backgroundColor = [NSColor whiteColor];
    }
    
    [self updateDefaultPreferences];
    
    //Register for drag and drop
    [self.mainTableview registerForDraggedTypes: @[CLDragSessionKey]];
    
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    
    self.reviewView.hidden = !self.showReviewCell;
    
    self.reviewView.layer.backgroundColor = (theme.integerValue == 0) ? [NSColor whiteColor].CGColor :  [NSColor blackColor].CGColor;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedFloatingWindow
{
    if (sharedFloatingWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedFloatingWindow = [[self alloc] initWithWindowNibName:@"CLFloatingWindow"];
            
        });
    }
    return sharedFloatingWindow;
}

- (void) updateDefaultPreferences
{
    [super updateDefaultPreferences];
    
    [self updateTime];
}

- (void)updateTime  
{
    [self.mainTableview reloadData];
}

- (void)removeContextHelpForSlider
{
    NSEvent *newEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                           location:self.window.mouseLocationOutsideOfEventStream
                                      modifierFlags:0
                                          timestamp:0
                                       windowNumber:self.window.windowNumber
                                            context:self.window.graphicsContext
                                        eventNumber:0
                                         clickCount:1
                                           pressure:0];
    [NSApp postEvent:newEvent atStart:NO];
    newEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
                                  location:self.window.mouseLocationOutsideOfEventStream
                             modifierFlags:0
                                 timestamp:0
                              windowNumber:self.window.windowNumber
                                   context:self.window.graphicsContext
                               eventNumber:0
                                clickCount:1
                                  pressure:0];
    
    [NSApp postEvent:newEvent atStart:NO];
}

-(void)windowWillClose:(NSNotification *)notification
{
    self.futureSliderValue = 0;
    self.timezoneDataSource.futureSliderValue = 0;
    
    if (self.floatingWindowTimer)
    {
        [self.floatingWindowTimer.timer invalidate];
        self.floatingWindowTimer = nil;
    }
}

- (void)startWindowTimer
{
    if (!self.floatingWindowTimer)
    {
        self.floatingWindowTimer = [CLPausableTimer timerWithTimeInterval:1.0
                                                                    target:self
                                                                  selector:@selector(updateTime) userInfo:nil
                                                                   repeats:YES];
        [self.floatingWindowTimer start]; //Explicitly start the timer
    }
}

- (void)updatePanelColor
{
    [super updatePanelColor];
    
    NSPanel *panel = (id)self.window;
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon-White"];
        self.preferencesButton.image = [NSImage imageNamed:@"Settings-White"];
        self.window.backgroundColor = [NSColor blackColor];
        panel.backgroundColor = [NSColor blackColor];
    }
    else
    {
        self.shutdownButton.image = [NSImage imageNamed:@"PowerIcon"];
        self.preferencesButton.image = [NSImage imageNamed:NSImageNameActionTemplate];
        self.window.backgroundColor = [NSColor whiteColor];
        panel.backgroundColor = [NSColor whiteColor];
    }

}


@end
