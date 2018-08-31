//
//  ConfigMacOSVersionControl.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigMacOSVersionControl.h"

@implementation ConfigMacOSVersionControl
- (instancetype) initWithLowest: (NSString *) lowestVersion {
    self->lowestVersion = lowestVersion;
    self->higestVersion = nil;
    return self;
}

- (instancetype) initWithHighest: (NSString *) higestVersion andLowest: (NSString *) lowestVersion {
    self->lowestVersion = lowestVersion;
    self->higestVersion = higestVersion;
    return self;
}

- (BOOL) compareWith: (NSString *) macOSVersion {
    // TODO Compare with max version and min version
    return YES;
}

- (BOOL) compareWithCurrent {
    return [self compareWith:[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"]];
}

+ (NSString *) getMacOSVersion {
    NSString *version = [[[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] componentsSeparatedByString:@"."] objectAtIndex:1];
    return [NSString stringWithFormat:@"10.%@", version];
}

+ (int) getMacOSVersionInInt {
    NSString *version = [[[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] componentsSeparatedByString:@"."] objectAtIndex:1];
    return version.intValue;
}

@end
