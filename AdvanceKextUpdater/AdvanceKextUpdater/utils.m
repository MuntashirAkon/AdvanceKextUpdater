//
//  utils.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/7/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "utils.h"

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
