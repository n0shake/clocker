//
//  PTKeyCombo.m
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//

#import "PTKeyCombo.h"
#import "PTKeyCodeTranslator.h"

@implementation PTKeyCombo

+ (id)clearKeyCombo
{
	return [self keyComboWithKeyCode: -1 modifiers: -1];
}

+ (id)keyComboWithKeyCode: (NSInteger)keyCode modifiers: (NSUInteger)modifiers
{
	return [[self alloc] initWithKeyCode: keyCode modifiers: modifiers];
}

- (id)initWithKeyCode: (NSInteger)keyCode modifiers: (NSUInteger)modifiers
{
	self = [super init];

	if( self )
	{
        switch ( keyCode )
        {
            case kVK_F1:
            case kVK_F2:
            case kVK_F3:
            case kVK_F4:
            case kVK_F5:
            case kVK_F6:
            case kVK_F7:
            case kVK_F8:
            case kVK_F9:
            case kVK_F10:
            case kVK_F11:
            case kVK_F12:
            case kVK_F13:
            case kVK_F14:
            case kVK_F15:
            case kVK_F16:
            case kVK_F17:
            case kVK_F18:
            case kVK_F19:
            case kVK_F20:
                mModifiers = modifiers | NSFunctionKeyMask;
                break;
            default:
                mModifiers = modifiers;
                break;
        }

		mKeyCode = keyCode;
	}

	return self;
}

- (id)initWithPlistRepresentation: (id)plist
{
	int keyCode, modifiers;

	if( !plist || ![plist count] )
	{
		keyCode = -1;
		modifiers = -1;
	}
	else
	{
		keyCode = [[plist objectForKey: @"keyCode"] intValue];
		if( keyCode < 0 ) keyCode = -1;

		modifiers = [[plist objectForKey: @"modifiers"] intValue];
		if( modifiers <= 0 ) modifiers = -1;
	}

	return [self initWithKeyCode: keyCode modifiers: modifiers];
}

- (id)plistRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInteger: [self keyCode]], @"keyCode",
				[NSNumber numberWithInteger: [self modifiers]], @"modifiers",
				nil];
}

- (id)copyWithZone:(NSZone*)zone;
{
	return self;
}

- (BOOL)isEqual: (PTKeyCombo*)combo
{
	return	[self keyCode] == [combo keyCode] &&
			[self modifiers] == [combo modifiers];
}

#pragma mark -

- (NSInteger)keyCode
{
	return mKeyCode;
}

- (NSUInteger)modifiers
{
	return mModifiers;
}

- (BOOL)isValidHotKeyCombo
{
	return mKeyCode >= 0 && mModifiers > 0;
}

- (BOOL)isClearCombo
{
	return mKeyCode == -1 && mModifiers == 0;
}

@end
