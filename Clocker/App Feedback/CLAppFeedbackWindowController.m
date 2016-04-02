//
//  CLAppFeedbackWindowController.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/24/15.
//
//

#import "CLAppFeedbackWindowController.h"
#import "CLOneWindowController.h"
#import "CommonStrings.h"

NSString *const CLAppFeedbackNibIdentifier = @"CLAppFeedbackWindow";
NSString *const CLParseAppFeedbackClassIdentifier = @"CLAppFeedback";
NSString *const CLParseAppFeedbackNoResponseString = @"Not Provided";
NSString *const CLParseAppFeedbackNameProperty = @"name";
NSString *const CLParseAppFeedbackEmailProperty = @"email";
NSString *const CLParseAppFeedbackFeedbackProperty = @"feedback";
NSString *const CLFeedbackAlertTitle = @"Thank you for helping make Clocker even better!";
NSString *const CLFeedbackAlertInformativeText = @"We owe you a candy. 😇";
NSString *const CLFeedbackAlertButtonTitle = @"Close";
NSString *const CLFeedbackNotEnteredErrorMessage = @"Please enter some feedback.";

static CLAppFeedbackWindowController *sharedFeedbackWindow = nil;

@interface CLAppFeedbackWindowController ()<NSWindowDelegate>
@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSTextField *emailField;
@property (unsafe_unretained) IBOutlet NSTextView *feedbackTextView;
@property (weak) IBOutlet NSTextField *informativeText;
@property (assign) BOOL activityInProgress;

@end

@implementation CLAppFeedbackWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
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
            sharedFeedbackWindow = [[self alloc] initPrivate];
            
        });
    }
    return sharedFeedbackWindow;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
    [NSException raise:@"Singleton" format:@"Use +[CLAppFeedbackWindowController sharedWindow]"];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super initWithWindowNibName:CLAppFeedbackNibIdentifier];
    return self;
}

- (IBAction)sendFeedback:(id)sender
{
    [self cleanUp];
    
    self.activityInProgress = YES;
    
    if (self.feedbackTextView.string.length == 0)
    {
        self.informativeText.stringValue = CLFeedbackNotEnteredErrorMessage;
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(cleanUp)
                                       userInfo:nil
                                        repeats:NO];
        self.activityInProgress = NO;
        return;
    }
    
    /*
    PFObject *feedbackObject = [PFObject objectWithClassName:CLParseAppFeedbackClassIdentifier];
    feedbackObject[CLParseAppFeedbackNameProperty] = (self.nameField.stringValue.length > 0) ?
    self.nameField.stringValue : CLParseAppFeedbackNoResponseString;
    feedbackObject[CLParseAppFeedbackEmailProperty] = (self.emailField.stringValue.length > 0) ?
    self.emailField.stringValue : CLParseAppFeedbackNoResponseString;
    feedbackObject[CLParseAppFeedbackFeedbackProperty] = self.feedbackTextView.string;
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
            NSAlert *alert = [NSAlert new];
            alert.messageText = NSLocalizedString(CLFeedbackAlertTitle, @"Thank you for helping make Clocker even better!");
            alert.informativeText = CLFeedbackAlertInformativeText;
            [alert addButtonWithTitle:CLFeedbackAlertButtonTitle];
            [alert beginSheetModalForWindow:self.window
                          completionHandler:^(NSModalResponse returnCode) {
                              [self.window close];
                          }];
        }
    }];
    
    
    */
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
    
    [[NSApplication sharedApplication].windows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([window.windowController isMemberOfClass:[CLOneWindowController class]]) {
            [window makeKeyAndOrderFront:self];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }];
    
}

@end
