//
//  NSString+CLStringAdditions.m
//  Clocker
//
//  Created by Abhishek Banthia on 7/20/16.
//
//

#import "NSString+CLStringAdditions.h"

@implementation NSString (CLStringAdditions)


- (NSString *)getFilteredNameForPlace
{
    NSString *filteredAddress = self;
    NSRange range = [self rangeOfString:@","];
    
    if (range.location != NSNotFound)
    {
        filteredAddress = [self substringWithRange:NSMakeRange(0, range.location)];
    }
    
    return filteredAddress;
}

@end
