

#import "MenubarController.h"
#import "StatusItemView.h"
#import "CLTimezoneData.h"
#import "ApplicationDelegate.h"
#import "CLTimezoneDataOperations.h"

typedef void (^CompletionType)(void);

@implementation MenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        // Install status item into the menu bar
        NSData *dataObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"favouriteTimezone"];
        
        NSStatusItem *statusItem;
        NSTextField *textField;
        
        if (dataObject)
        {
            CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:dataObject];
            CLTimezoneDataOperations *operationObject = [[CLTimezoneDataOperations alloc] initWithTimezoneData:timezoneObject];
            
            
            NSString *menuTitle = [operationObject getMenuTitle];
            
            textField = [self setUpTextfieldForMenubar];
            textField.stringValue = (menuTitle.length > 0) ? menuTitle : @"Icon";
            [textField sizeToFit];
            
           statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:textField.frame.size.width+3];
            
            [self setUpTimerForUpdatingMenubar];
            
        }
        else
        {
            statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
            
            [self invalidateTimerForMenubar];
        }
       
        _statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
        _statusItemView.image = dataObject ? [self convertTextfieldRepresentationToImage:textField] : [NSImage imageNamed:@"MenuIcon"];
        _statusItemView.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
        _statusItemView.action = @selector(togglePanel:);
        
    }
    
    return self;
}

- (NSTextField *)setUpTextfieldForMenubar
{
    NSTextField *textField= [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, STATUS_ITEM_VIEW_WIDTH, 22)];
    textField.backgroundColor = [NSColor whiteColor];
    textField.bordered = NO;
    textField.textColor = [NSColor blackColor];
    textField.alignment = NSTextAlignmentCenter;
    
    return textField;
}

- (void)updateMenubar
{
    [self.statusItemView setNeedsDisplay:YES];
}

- (void)setUpTimerForUpdatingMenubar
{
    self.checkIfMenubarUpdatingWasCancelled = NO;
    [self tryingSomethingHere];
}

- (void)tryingSomethingHere
{

    //a block calling itself without the ARC retain warning
    __block CompletionType completionBlock = nil;
    __block __weak CompletionType weakCompletionBlock = nil;
    completionBlock = ^(void) {
        
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            
            if(!self.checkIfMenubarUpdatingWasCancelled)
            {
                [self updateMenubar];
                weakCompletionBlock = completionBlock;
                weakCompletionBlock();
            }
        });
    };
    
    completionBlock();
}

- (void)stoppingTheMenubar
{
    self.checkIfMenubarUpdatingWasCancelled = YES;
    [self.statusItemView setNeedsDisplay:YES];
}

- (void)invalidateTimerForMenubar
{
    [self stoppingTheMenubar];
}

- (NSImage *)convertTextfieldRepresentationToImage:(NSTextField *)textField
{
    NSSize textfieldSize = textField.bounds.size;
    NSSize imgSize = NSMakeSize(textfieldSize.width, textfieldSize.height);
    
    NSBitmapImageRep *bitmapRepresentation = [textField bitmapImageRepForCachingDisplayInRect:textField.bounds];
    bitmapRepresentation.size = imgSize;
    [textField cacheDisplayInRect:textField.bounds toBitmapImageRep:bitmapRepresentation];
    
    NSImage* image = [[NSImage alloc] initWithSize:imgSize];
    [image addRepresentation:bitmapRepresentation];
    return image;
    
}

- (void)dealloc
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark -
#pragma mark Public accessors

- (NSStatusItem *)statusItem
{
    return self.statusItemView.statusItem;
}

#pragma mark -

- (BOOL)hasActiveIcon
{
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag
{
    self.statusItemView.isHighlighted = flag;
}

@end
