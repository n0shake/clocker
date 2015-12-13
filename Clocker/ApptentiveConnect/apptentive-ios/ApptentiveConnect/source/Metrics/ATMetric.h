//
//  ATMetric.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATRecord.h"

@interface ATMetric : ATRecord <NSCoding> {
@private
	NSString *name;
	NSMutableDictionary *info;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) NSDictionary *info;

- (void)setValue:(id)value forKey:(NSString *)key;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
