//
//  utils.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/7/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <SystemConfiguration/SystemConfiguration.h>
#import <stdlib.h> // tty() related fns
#import "utils.h"

/// Print to any file stream
/// @param stream The file stream, can be any FILE stream or stdin, stdout, stderr
/// @param format The string to be printed
void _fprintf(FILE *stream, NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *string = [NSString.alloc initWithFormat:format arguments:arguments];
    va_end(arguments);
    fprintf(stream, "%s", [string UTF8String]);
}

/// Print to stdout
/// @param format The string to be printed
void _printf(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *string = [NSString.alloc initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s", [string UTF8String]);
}

///
/// Run and get the output of a command
/// @param cmd The command
/// @param output Output in either NSString or NSArray
/// @return exit code
///
int tty(NSString *cmd, _Nullable id *output) {
    FILE *fp;
    char o[1035];
    // Open the command for reading.
    fp = popen([NSString stringWithFormat:@"/bin/sh -c \"%@\" 2>&1", cmd].UTF8String, "r");
    // Return -1 on failure
    if (fp == NULL) return -1;
    // Read the output if requested
    if(output == NULL){
        while (fgets(o, sizeof(o), fp) != NULL) {};
    } else if ([*output isKindOfClass:NSArray.class]) {
        NSMutableArray<NSString *> *outputArr = NSMutableArray.array;
        while (fgets(o, sizeof(o), fp) != NULL) {
            [outputArr addObject:[NSString stringWithUTF8String:o]];
        }
        *output = outputArr.copy;
    } else if ([*output isKindOfClass:NSString.class]) {
        NSMutableString *outputStr = NSMutableString.string;
        while (fgets(o, sizeof(o), fp) != NULL) {
            [outputStr appendString:[NSString stringWithUTF8String:o]];
        }
        *output = [outputStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    } else {
        while (fgets(o, sizeof(o), fp) != NULL) {};
    }
    // close
    return pclose(fp)/256;
}

/// Check whether the user has active internet connection
/// @return YES if user has an active internet connection, NO otherwise
/// @see https://stackoverflow.com/a/18750343/4147849
BOOL hasInternetConnection() {
    BOOL returnValue = NO;
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)&zeroAddress);
    if (reachabilityRef != NULL){
        SCNetworkReachabilityFlags flags = 0;
        if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
            BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
            BOOL connectionRequired = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
            returnValue = (isReachable && !connectionRequired) ? YES : NO;
        }
        CFRelease(reachabilityRef);
    }
    return returnValue;
}

BOOL isRootUser() {
    uid_t uid = getuid();
    return uid == 0 ? YES : NO;
}

NSString *getMainUser(){
    NSString *output = NSString.string;
    tty(@"/usr/bin/logname", &output);
    return output;
}

/// @see https://stackoverflow.com/a/24811200/4147849
@implementation NSString (VersionNumbers)
/// Shorten the version number, ie. remove unnecessary 0's
/// as they create problem when comparing with other version
/// @return Shortened version
- (NSString *) shortenedVersionNumberString {
    static NSString *const unnecessaryVersionSuffix = @".0";
    NSString *shortenedVersionNumber = self;
    while ([shortenedVersionNumber hasSuffix:unnecessaryVersionSuffix]) {
        shortenedVersionNumber = [shortenedVersionNumber substringToIndex:shortenedVersionNumber.length - unnecessaryVersionSuffix.length];
    }
    return shortenedVersionNumber;
}
@end

@implementation NSArray (MatchFromStringToRegex)
/// Matches the given string using the array of RegEx string
/// @param string The string to be matched
/// @return YES if matches, NO otherwise
- (BOOL) usingArrayMemberAsRegexMatchString: (NSString *) string {
    NSArray *tmpArray = self;
    for(NSString *str in tmpArray){
        /// @see https://stackoverflow.com/a/14916948/4147849
        if([string rangeOfString:str options:NSRegularExpressionSearch].location != NSNotFound) return YES;
    }
    return NO;
}
@end
