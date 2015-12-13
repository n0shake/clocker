//
//  ATUtilitiesTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/15/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATUtilitiesTests.h"


@implementation ATUtilitiesTests
- (void)testEvenRect {
	CGRect testRect1 = CGRectMake(0.0, 0.0, 17.0, 21.0);
	CGRect result1 = ATCGRectOfEvenSize(testRect1);
	STAssertEquals(result1.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result1.size.height, (CGFloat)22.0, @"");
	
	CGRect testRect2 = CGRectMake(0.0, 0.0, 18.0, 22.0);
	CGRect result2 = ATCGRectOfEvenSize(testRect2);
	STAssertEquals(result2.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result2.size.height, (CGFloat)22.0, @"");
}

- (void)testDateFormatting {
	// This test will only pass when the time zone is PST. *sigh*
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1322609978.669914];
	STAssertEqualObjects(@"2011-11-29 15:39:38.669914 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.669];
	STAssertEqualObjects(@"2011-11-29 15:39:38.669 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	STAssertEqualObjects(@"2011-11-29 15:39:38 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	STAssertEqualObjects(@"2011-11-29 23:39:38 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]], @"date doesn't match");
	
	NSString *string = @"2012-09-07T23:01:07+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07Z";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+02:33";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 20:28:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
}

- (void)testVersionComparisons {
	STAssertTrue([ATUtilities versionString:@"6.0" isEqualToVersionString:@"6.0"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"0.0" isEqualToVersionString:@"0.0"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"6.0.1" isEqualToVersionString:@"6.0.1"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"0.0.1" isEqualToVersionString:@"0.0.1"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"10.10.1" isEqualToVersionString:@"10.10.1"], @"Should be same");
	
	STAssertTrue([ATUtilities versionString:@"10.10.1" isGreaterThanVersionString:@"10.10.0"], @"Should be greater");
	STAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.0.1"], @"Should be greater");
	STAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.1"], @"Should be greater");
	
	STAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"5.1"], @"Should be less");
	STAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"6.0.1"], @"Should be less");
}

- (void)testCacheControlParsing {
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:nil], @"Should be same");
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:@""], @"Should be same");
	STAssertEquals(86400., [ATUtilities maxAgeFromCacheControlHeader:@"Cache-Control: max-age=86400, private"], @"Should be same");
	STAssertEquals(86400., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=86400, private"], @"Should be same");
	STAssertEquals(47.47, [ATUtilities maxAgeFromCacheControlHeader:@"max-age=47.47, private"], @"Should be same");
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=0, private"], @"Should be same");
}
@end
