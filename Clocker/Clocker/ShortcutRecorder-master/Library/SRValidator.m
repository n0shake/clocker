//
//  SRValidator.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim
//      Silvio Rizzi
//      Ilya Kulakov

#import "SRValidator.h"
#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"


@implementation SRValidator

- (instancetype)initWithDelegate:(NSObject<SRValidatorDelegate> *)aDelegate;
{
    self = [super init];

    if (self)
    {
        _delegate = aDelegate;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithDelegate:nil];
}


#pragma mark Methods

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSEventModifierFlags)aFlags error:(NSError **)outError;
{
    if ([self isKeyCode:aKeyCode andFlagTakenInDelegate:aFlags error:outError])
        return YES;

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckSystemShortcuts:)] ||
         [self.delegate shortcutValidatorShouldCheckSystemShortcuts:self]) &&
        [self isKeyCode:aKeyCode andFlagsTakenInSystemShortcuts:aFlags error:outError])
    {
        return YES;
    }

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckMenu:)] ||
         [self.delegate shortcutValidatorShouldCheckMenu:self]) &&
        [self isKeyCode:aKeyCode andFlags:aFlags takenInMenu:[NSApp mainMenu] error:outError])
    {
        return YES;
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagTakenInDelegate:(NSEventModifierFlags)aFlags error:(NSError **)outError
{
    if (self.delegate)
    {
        NSString *delegateReason = nil;
        if ([self.delegate respondsToSelector:@selector(shortcutValidator:isKeyCode:andFlagsTaken:reason:)] &&
            [self.delegate shortcutValidator:self
                                   isKeyCode:aKeyCode
                               andFlagsTaken:aFlags
                                      reason:&delegateReason])
        {
            if (outError)
            {
                BOOL isASCIIOnly = YES;

                if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                    isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                NSString *failureReason = [NSString stringWithFormat:
                                           SRLoc(@"The key combination \"%@\" can't be used!"),
                                           shortcut];
                NSString *description = [NSString stringWithFormat:
                                         SRLoc(@"The key combination \"%@\" can't be used because %@."),
                                         shortcut,
                                         [delegateReason length] ? delegateReason : @"it's already used"];
                NSDictionary *userInfo = @{
                    NSLocalizedFailureReasonErrorKey : failureReason,
                    NSLocalizedDescriptionKey: description
                };
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            }

            return YES;
        }
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTakenInSystemShortcuts:(NSEventModifierFlags)aFlags error:(NSError **)outError
{
    CFArrayRef s = NULL;
    OSStatus err = CopySymbolicHotKeys(&s);

    if (err != noErr)
        return YES;

    NSArray *symbolicHotKeys = (NSArray *)CFBridgingRelease(s);
    aFlags &= SRCocoaModifierFlagsMask;

    for (NSDictionary *symbolicHotKey in symbolicHotKeys)
    {
        if ((__bridge CFBooleanRef)symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyEnabled] != kCFBooleanTrue)
            continue;

        unsigned short symbolicHotKeyCode = [symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyCode] integerValue];

        if (symbolicHotKeyCode == aKeyCode)
        {
            UInt32 symbolicHotKeyFlags = [symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyModifiers] unsignedIntValue];
            symbolicHotKeyFlags &= SRCarbonModifierFlagsMask;

            if (SRCarbonToCocoaFlags(symbolicHotKeyFlags) == aFlags)
            {
                if (outError)
                {
                    BOOL isASCIIOnly = YES;

                    if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                        isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                    NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                    NSString *failureReason = [NSString stringWithFormat:
                                               SRLoc(@"The key combination \"%@\" can't be used!"),
                                               shortcut];
                    NSString *description = [NSString stringWithFormat:
                                             SRLoc(@"The key combination \"%@\" can't be used because it's already used by a system-wide keyboard shortcut. If you really want to use this key combination, most shortcuts can be changed in the Keyboard panel in System Preferences."),
                                             shortcut];
                    NSDictionary *userInfo = @{
                        NSLocalizedFailureReasonErrorKey: failureReason,
                        NSLocalizedDescriptionKey: description
                    };
                    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
                }

                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlags:(NSEventModifierFlags)aFlags takenInMenu:(NSMenu *)aMenu error:(NSError **)outError
{
    aFlags &= SRCocoaModifierFlagsMask;

    for (NSMenuItem *menuItem in [aMenu itemArray])
    {
        if (menuItem.hasSubmenu && [self isKeyCode:aKeyCode andFlags:aFlags takenInMenu:menuItem.submenu error:outError])
            return YES;

        NSString *keyEquivalent = menuItem.keyEquivalent;

        if (![keyEquivalent length])
            continue;

        NSEventModifierFlags keyEquivalentModifierMask = menuItem.keyEquivalentModifierMask;

        if (SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(aKeyCode, aFlags, keyEquivalent, keyEquivalentModifierMask))
        {
            if (outError)
            {
                BOOL isASCIIOnly = YES;

                if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                    isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                NSString *failureReason = [NSString stringWithFormat:SRLoc(@"The key combination \"%@\" can't be used!"), shortcut];
                NSString *description = [NSString stringWithFormat:SRLoc(@"The key combination \"%@\" can't be used because it's already used by the menu item \"%@\"."), shortcut, menuItem.SR_path];
                NSDictionary *userInfo = @{
                    NSLocalizedFailureReasonErrorKey: failureReason,
                    NSLocalizedDescriptionKey: description
                };
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            }

            return YES;
        }
    }

    return NO;
}

@end


@implementation NSMenuItem (SRValidator)

- (NSString *)SR_path
{
    NSMutableArray *items = [NSMutableArray array];
    static const NSUInteger Limit = 1000;
    NSMenuItem *currentMenuItem = self;
    NSUInteger i = 0;

    do
    {
        [items insertObject:currentMenuItem atIndex:0];
        currentMenuItem = currentMenuItem.parentItem;
        ++i;
    }
    while (currentMenuItem && i < Limit);

    NSMutableString *path = [NSMutableString string];

    for (NSMenuItem *menuItem in items)
        [path appendFormat:@"%@➝", menuItem.title];

    if ([path length] > 1)
        [path deleteCharactersInRange:NSMakeRange([path length] - 1, 1)];

    return path;
}

@end
