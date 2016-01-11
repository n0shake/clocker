//
//  CLAPI.h
//  Clocker
//
//  Created by Abhishek Banthia on 1/10/16.
//
//

#import <Foundation/Foundation.h>

@interface CLAPI : NSObject

+ (void)dataTaskWithServicePath:(NSString *)path
                                       bySender:(id)sender
                            withCompletionBlock:(void (^)(NSError *error, NSDictionary *dictionary))completionBlock;

+ (BOOL)isUserConnectedToInternet;

@end
