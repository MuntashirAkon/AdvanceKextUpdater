//
//  utils.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/7/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <SystemConfiguration/SystemConfiguration.h>
#import "utils.h"

// @see https://stackoverflow.com/a/18750343/4147849
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

// @see https://stackoverflow.com/a/24811200/4147849
@implementation NSString (VersionNumbers)
- (NSString *) shortenedVersionNumberString {
    static NSString *const unnecessaryVersionSuffix = @".0";
    NSString *shortenedVersionNumber = self;
    while ([shortenedVersionNumber hasSuffix:unnecessaryVersionSuffix]) {
        shortenedVersionNumber = [shortenedVersionNumber substringToIndex:shortenedVersionNumber.length - unnecessaryVersionSuffix.length];
    }
    return shortenedVersionNumber;
}
@end

// Matches the given string using the array of RegEx string
@implementation NSArray (MatchFromStringToRegex)
- (BOOL) usingArrayMemberAsRegexMatchString: (NSString *) string {
    NSArray *tmpArray = self;
    for(NSString *str in tmpArray){
        // @see https://stackoverflow.com/a/14916948/4147849
        if([string rangeOfString:str options:NSRegularExpressionSearch].location != NSNotFound) return YES;
    }
    return NO;
}
@end
