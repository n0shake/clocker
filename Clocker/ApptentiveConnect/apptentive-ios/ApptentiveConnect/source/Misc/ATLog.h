//
//  ATLog.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/29/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATLogger.h"

#ifndef AT_LOGGING_ENABLED
#	define AT_LOGGING_ENABLED 1
#endif

#ifndef AT_LOGGING_LEVEL_DEBUG
#	define AT_LOGGING_LEVEL_DEBUG 0
#endif

#ifndef AT_LOGGING_LEVEL_INFO
#	define AT_LOGGING_LEVEL_INFO 0
#endif

#ifndef AT_LOGGING_LEVEL_ERROR
#	define AT_LOGGING_LEVEL_ERROR 1
#endif

#if !(defined(AT_LOGGING_ENABLED) && AT_LOGGING_ENABLED)
#	undef AT_LOGGING_LEVEL_DEBUG
#	undef AT_LOGGING_LEVEL_INFO
#	undef AT_LOGGING_LEVEL_ERROR
#endif

#define AT_LOG_FORMAT(format_val, level, ...) ([ATLogger logWithLevel:level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ format:(format_val), ##__VA_ARGS__ ])

#if AT_LOGGING_LEVEL_DEBUG
#	define ATLogDebug(s, ...) AT_LOG_FORMAT(s, @"debug", ##__VA_ARGS__)
#else
#	define ATLogDebug(s, ...)
#endif

#if AT_LOGGING_LEVEL_INFO
#	define ATLogInfo(s, ...) AT_LOG_FORMAT(s, @"info", ##__VA_ARGS__)
#else
#	define ATLogInfo(s, ...)
#endif

#if AT_LOGGING_LEVEL_ERROR
#	define ATLogError(s, ...) AT_LOG_FORMAT(s, @"error", ##__VA_ARGS__)
#else
#	define ATLogError(s, ...)
#endif

