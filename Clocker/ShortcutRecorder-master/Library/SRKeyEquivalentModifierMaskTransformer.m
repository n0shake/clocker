//
//  SRKeyEquivalentModifierMaskTransformer.m
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRKeyEquivalentModifierMaskTransformer.h"
#import "SRKeyCodeTransformer.h"
#import "SRRecorderControl.h"


@implementation SRKeyEquivalentModifierMaskTransformer

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (NSNumber *)transformedValue:(NSDictionary *)aValue
{
    if (![aValue isKindOfClass:[NSDictionary class]])
        return @(0);

    NSNumber *modifierFlags = aValue[SRShortcutModifierFlagsKey];

    if (![modifierFlags isKindOfClass:[NSNumber class]])
        return @(0);

    return modifierFlags;
}

@end
