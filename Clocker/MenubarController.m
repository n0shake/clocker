

#import "MenubarController.h"
#import "StatusItemView.h"
#import "CLTimezoneData.h"
#import "ApplicationDelegate.h"

@implementation MenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        // Install status item into the menu bar
        NSData *dataObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"favouriteTimezone"];
        NSString *menuTitle = [NSString new];
        if (dataObject) {
            CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:dataObject];
            menuTitle = [timezoneObject getMenuTitle];
        }
        
        NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, STATUS_ITEM_VIEW_WIDTH, 18)];
        textField.backgroundColor = [NSColor whiteColor];
        textField.bordered = NO;
        textField.textColor = [NSColor blackColor];
        textField.alignment = NSTextAlignmentCenter;
        textField.stringValue = (menuTitle.length > 0) ? menuTitle : @"Icon";
        [textField sizeToFit];
        
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:textField.frame.size.width+3];
     
        _statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
        _statusItemView.image = [self imageWithSubviewsWithTextField:textField];
        _statusItemView.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
        _statusItemView.action = @selector(togglePanel:);
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(updateIconDisplay)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

- (void)updateIconDisplay
{
    [self.statusItemView setNeedsDisplay:YES];
}

- (NSImage *)imageWithSubviewsWithTextField:(NSTextField *)textField
{
    NSSize mySize = textField.bounds.size;
    NSSize imgSize = NSMakeSize( mySize.width, mySize.height );
    
    NSBitmapImageRep *bir = [textField bitmapImageRepForCachingDisplayInRect:[textField bounds]];
    [bir setSize:imgSize];
    [textField cacheDisplayInRect:[textField bounds] toBitmapImageRep:bir];
    
    NSImage* image = [[NSImage alloc]initWithSize:imgSize];
    [image addRepresentation:bir];
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
