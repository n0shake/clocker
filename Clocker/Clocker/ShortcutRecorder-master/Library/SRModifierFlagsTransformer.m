//
//  SRModifierFlagsTransformer.m
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRModifierFlagsTransformer.h"
#import "SRCommon.h"


@implementation SRModifierFlagsTransformer

- (instancetype)initWithPlainStrings:(BOOL)aUsesPlainStrings
{
    self = [super init];

    if (self)
    {
        _usesPlainStrings = aUsesPlainStrings;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithPlainStrings:NO];
}


#pragma mark Methods

+ (instancetype)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [[self alloc] initWithPlainStrings:NO];
    });
    return Transformer;
}

+ (instancetype)sharedPlainTransformer
{
    static dispatch_once_t OnceToken;
    static SRModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [[self alloc] initWithPlainStrings:YES];
    });
    return Transformer;
}


#pragma mark NSValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString *)transformedValue:(NSNumber *)aValue
{
    if (![aValue isKindOfClass:[NSNumber class]])
        return nil;
    else if (self.usesPlainStrings)
    {
        NSEventModifierFlags modifierFlags = [aValue unsignedIntegerValue];
        NSMutableString *s = [NSMutableString string];

        if (modifierFlags & NSControlKeyMask)
            [s appendString:SRLoc(@"Control-")];

        if (modifierFlags & NSAlternateKeyMask)
            [s appendString:SRLoc(@"Option-")];

        if (modifierFlags & NSShiftKeyMask)
            [s appendString:SRLoc(@"Shift-")];

        if (modifierFlags & NSCommandKeyMask)
            [s appendString:SRLoc(@"Command-")];

        if (s.length > 0)
            [s deleteCharactersInRange:NSMakeRange(s.length - 1, 1)];

        return s;
    }
    else
    {
        NSEventModifierFlags f = [aValue unsignedIntegerValue];
        return [NSString stringWithFormat:@"%@%@%@%@",
                (f & NSControlKeyMask ? @"⌃" : @""),
                (f & NSAlternateKeyMask ? @"⌥" : @""),
                (f & NSShiftKeyMask ? @"⇧" : @""),
                (f & NSCommandKeyMask ? @"⌘" : @"")];
    }
}

@end
