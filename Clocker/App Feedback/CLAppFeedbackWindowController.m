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
    
    
    NSMutableDictionary *feedbackInfo = [[NSMutableDictionary alloc] init];
    [feedbackInfo setObject:(self.nameField.stringValue.length > 0) ?
    self.nameField.stringValue : CLParseAppFeedbackNoResponseString forKey:CLParseAppFeedbackNameProperty];
    [feedbackInfo setObject:(self.emailField.stringValue.length > 0) ?
     self.emailField.stringValue : CLParseAppFeedbackNoResponseString forKey:CLParseAppFeedbackEmailProperty];
    [feedbackInfo setObject:self.feedbackTextView.string forKey:CLParseAppFeedbackFeedbackProperty ];
    
    // Create a reference to a Firebase database URL
    Firebase *myRootRef = [[Firebase alloc] initWithUrl:@"https://fiery-heat-5237.firebaseio.com/Feedback"];
    Firebase *feedbackRef = [myRootRef childByAppendingPath:[self getSerialNumber]];
    // Write data to Firebase
    
    [feedbackRef setValue:feedbackInfo];
   
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
     
- (NSString *)getSerialNumber
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
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
