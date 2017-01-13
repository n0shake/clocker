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
#import <Firebase/Firebase.h>

NSString *const CLAppFeedbackNibIdentifier = @"CLAppFeedbackWindow";
NSString *const CLAppFeedbackNoResponseString = @"Not Provided";
NSString *const CLAppFeedbackNameProperty = @"name";
NSString *const CLAppFeedbackEmailProperty = @"email";
NSString *const CLAppFeedbackFeedbackProperty = @"feedback";
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
    [self resetInformativeTextLabel];
    
    self.activityInProgress = YES;
    
    if (![self didUserEnterFeedback]){
        return;
    }
    
    NSMutableDictionary *feedbackInfo = [self retrieveDataForSending];
    [self sendDataToFirebase:feedbackInfo];
    [self showDataConfirmation];

}

- (BOOL)didUserEnterFeedback
{
    NSString *cleanedUpString = [self.feedbackTextView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleanedUpString.length == 0)
    {
        self.informativeText.stringValue = CLFeedbackNotEnteredErrorMessage;
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(resetInformativeTextLabel)
                                       userInfo:nil
                                        repeats:NO];
        self.activityInProgress = NO;
        return NO;
    }
    
    return YES;
}

- (NSMutableDictionary *)retrieveDataForSending
{
    NSMutableDictionary *feedbackInfo = [[NSMutableDictionary alloc] init];
    feedbackInfo[CLAppFeedbackNameProperty] = (self.nameField.stringValue.length > 0) ?
    self.nameField.stringValue : CLAppFeedbackNoResponseString;
    feedbackInfo[CLAppFeedbackEmailProperty] = (self.emailField.stringValue.length > 0) ?
    self.emailField.stringValue : CLAppFeedbackNoResponseString;
    feedbackInfo[CLAppFeedbackFeedbackProperty] = self.feedbackTextView.string;
    
    return feedbackInfo;
}

- (void)sendDataToFirebase:(NSDictionary *)feedbackInfo
{
    Firebase *myRootRef = [[Firebase alloc] initWithUrl:@"https://fiery-heat-5237.firebaseio.com/Feedback"];
    Firebase *feedbackRef = [myRootRef childByAppendingPath:[self getSerialNumber]];
    [feedbackRef setValue:feedbackInfo];
}

- (void)showDataConfirmation
{
    self.activityInProgress = NO;
    
    NSAlert *alert = [NSAlert new];
    alert.messageText = NSLocalizedString(CLFeedbackAlertTitle, @"Thank you for helping make Clocker even better!");
    alert.informativeText = CLFeedbackAlertInformativeText;
    [alert addButtonWithTitle:CLFeedbackAlertButtonTitle];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      [self.window close];
                  }];
}

- (void)resetInformativeTextLabel
{
    self.informativeText.stringValue = CLEmptyString;
}

- (IBAction)cancel:(id)sender
{
    [self.window close];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [self resetInformativeTextLabel];
    [self performClosingCleanUp];
    [self bringPreferencesWindowToFront];
}

- (void)performClosingCleanUp
{
    self.nameField.stringValue = CLEmptyString;
    self.emailField.stringValue = CLEmptyString;
    self.feedbackTextView.string = CLEmptyString;
    self.activityInProgress = NO;
}

-(void)bringPreferencesWindowToFront
{
    CLOneWindowController *oneWindowController = [CLOneWindowController sharedWindow];
    [oneWindowController.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (NSString *)getSerialNumber
{
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}

@end
