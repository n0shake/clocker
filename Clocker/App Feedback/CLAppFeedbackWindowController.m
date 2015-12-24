//
//  CLAppFeedbackWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/24/15.
//
//

#import "CLAppFeedbackWindowController.h"
#import <Parse/Parse.h>
#import "CLOneWindowController.h"
#import "CommonStrings.h"

NSString *const CLAppFeedbackNibIdentifier = @"CLAppFeedbackWindow";

static CLAppFeedbackWindowController *sharedFeedbackWindow = nil;

@interface CLAppFeedbackWindowController ()
@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSTextField *emailField;
@property (unsafe_unretained) IBOutlet NSTextView *feedbackTextView;
@property (weak) IBOutlet NSTextField *informativeText;
@property (assign) BOOL activityInProgress;

@end

@implementation CLAppFeedbackWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8)]; //RGB plus Alpha Channel
    [self.window.contentView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.window.contentView setLayer:viewLayer];
    self.window.titlebarAppearsTransparent = YES;
    
    self.window.backgroundColor = [NSColor whiteColor];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (instancetype)sharedWindow
{
    if (sharedFeedbackWindow == nil)
    {
        /*Using a thread safe pattern*/
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedFeedbackWindow = [[self alloc] initWithWindowNibName:CLAppFeedbackNibIdentifier];
            
        });
    }
    return sharedFeedbackWindow;
}

- (IBAction)sendFeedback:(id)sender
{
    [self cleanUp];
    
    self.activityInProgress = YES;
    
    if (self.feedbackTextView.string.length == 0)
    {
        self.informativeText.stringValue = @"Yo, enter some feedback!";
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(cleanUp)
                                       userInfo:nil
                                        repeats:NO];
        self.activityInProgress = NO;
        return;
    }
    
    PFObject *feedbackObject = [PFObject objectWithClassName:@"CLAppFeedback"];
    feedbackObject[@"name"] = (self.nameField.stringValue.length > 0) ?
                               self.nameField.stringValue : @"Not Provided";
    feedbackObject[@"email"] = (self.emailField.stringValue.length > 0) ?
                                self.emailField.stringValue : @"Not Provided";
    feedbackObject[@"feedback"] = self.feedbackTextView.string;
    [feedbackObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        self.activityInProgress = NO;
        if (!succeeded) {
            self.informativeText.stringValue = error.localizedDescription;
            [NSTimer scheduledTimerWithTimeInterval:10.0
                                             target:self
                                           selector:@selector(cleanUp)
                                           userInfo:nil
                                            repeats:NO];
            
        }
        else
        {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Thank you for helping make Clocker even better!";
            alert.informativeText = @"We owe you a candy. 😇";
            [alert addButtonWithTitle:@"Close"];
            [alert beginSheetModalForWindow:self.window
                                            completionHandler:^(NSModalResponse returnCode) {
                                                [self.window close];
                                            }];
        }
    }];
    
    

}

- (void)cleanUp
{
    self.informativeText.stringValue = CLEmptyString;
}

- (IBAction)cancel:(id)sender
{
    [self.window close];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [self cleanUp];
    self.nameField.stringValue = CLEmptyString;
    self.emailField.stringValue = CLEmptyString;
    self.feedbackTextView.string = CLEmptyString;
    self.activityInProgress = NO;
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        if ([window.windowController isMemberOfClass:[CLOneWindowController class]]) {
            [window makeKeyAndOrderFront:self];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }

}

@end
