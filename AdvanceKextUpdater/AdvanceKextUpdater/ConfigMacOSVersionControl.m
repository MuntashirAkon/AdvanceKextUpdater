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
@synthesize higestVersion;
@synthesize lowestVersion;

- (instancetype) initWithLowest: (NSString *) lowestVersion {
    self.lowestVersion = lowestVersion;
    self.higestVersion = nil;
    return self;
}

- (instancetype) initWithHighest: (id) higestVersion andLowest: (NSString *) lowestVersion {
    if(higestVersion == NSNull.null)
        return [self initWithLowest:lowestVersion];
    
    self.lowestVersion = lowestVersion;
    self.higestVersion = higestVersion;
    return self;
}

- (BOOL) installableIn: (NSString *) macOSVersion {
    if([lowestVersion compare:macOSVersion options:NSNumericSearch] != NSOrderedDescending){
        if(higestVersion == nil || [higestVersion compare:macOSVersion options:NSNumericSearch] == NSOrderedDescending) {
            return YES;
        }
    }
    return NO;
}

- (BOOL) installableInCurrentVersion {
    return [self installableIn:ConfigMacOSVersionControl.getMacOSVersion];
}

+ (NSString *) getMacOSVersion {
    return [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];
}

+ (int) getMacOSVersionInInt {
    NSString *version = [[[self getMacOSVersion] componentsSeparatedByString:@"."] objectAtIndex:1];
    return version.intValue;
}

@end
