//
//  CLAPI.m
//  Clocker
//
//  Created by Abhishek Banthia on 1/10/16.
//
//

#import "CLAPI.h"
#import "Reachability.h"

@implementation CLAPI

+ (void)dataTaskWithServicePath:(NSString *)path
                                       bySender:(id)sender
                            withCompletionBlock:(void (^)(NSError *error, NSDictionary *dictionary))completionBlock
{

    __block NSDictionary *responseDictionary = [NSDictionary dictionary];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    sessionConfig.timeoutIntervalForRequest = 20;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", path]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *dataTask = [session
                                          dataTaskWithRequest:request
                                          completionHandler:^(NSData *data,
                                                              NSURLResponse *response,
                                                              NSError *error)
                                          {
                                              
                                              /*Check if any error. If nil then proceed*/
                                              if (error == nil)
                                              {
                                                  NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                                                  if (httpResp.statusCode == 200)
                                                  {
                                                      responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                      completionBlock(error, responseDictionary);
                                                  }
                                              }
                                              /*Error is not nil. Show error*/
                                              else
                                              {
                                                  completionBlock(error, nil);

                                              }
                                          }];
    
    [dataTask resume];
    
}

+ (BOOL)isUserConnectedToInternet
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable)
    {
        return NO;
    }
    
    return YES;
}


@end
