//
//  ConfigVersionControl.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigVersionControl.h"

@implementation ConfigVersion
@synthesize version;
@synthesize config;
@synthesize macOSVersion;
@end

@implementation ConfigVersionControl
- (instancetype) initWithSelfConfig: (KextConfig *) baseConfig andOtherVersions: (id) otherVersions {
    self.currentVersion = baseConfig.version;
    NSMutableArray<ConfigVersion *> *availableVersions = NSMutableArray.array;
    // Add the base config to the list first
    ConfigVersion *tmpConfig = [ConfigVersion.alloc init];
    tmpConfig.version = baseConfig.version;
    tmpConfig.config  = baseConfig;
    tmpConfig.macOSVersion = baseConfig.macOSVersion;
    [availableVersions addObject:tmpConfig];
    // Add other config based on version
    if([otherVersions isKindOfClass:NSArray.class]){
        for(NSDictionary *version in otherVersions){
            ConfigVersion *tmpConfig = [ConfigVersion.alloc init];
            tmpConfig.version = [version objectForKey:@"version"];
            [versions addObject:tmpConfig.version];
            if(baseConfig.url == nil) { // Not a URL
                tmpConfig.config = [KextConfig.alloc initWithConfig:[NSString stringWithFormat:@"%@/%@", baseConfig.path, [version objectForKey:@"location"]]];
            } else { // A URL
                tmpConfig.config = [KextConfig.alloc initWithKextName:baseConfig.name URL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseConfig.url, [version objectForKey:@"location"]]]];
            }
            tmpConfig.macOSVersion = tmpConfig.config.macOSVersion;
            [availableVersions addObject:tmpConfig];
        }
    }
    self.availableVersions = availableVersions.copy;
    return self;
}

// BUG ALERT!!!
/**
 * Finds the best version of the kext for the current macOS
 *
 * @return -1 for none, positive integer if avialable
 */
- (NSInteger) findTheBestVersion {
    // Since the first version in the availableVersions is the latest version
    // (others may or may not be sequencial), check if it supports the current
    // version of macOS. If it does, don't need to iterate over the other versions
    if([self.availableVersions objectAtIndex:0].macOSVersion.installableInCurrentVersion) {
        return 0;
    }
    NSInteger n = [versions count];
    // If there are no other versions, return -1
    if(n == 0) return -1;
    else if (n >= 2){ // Sort the versions only if n>=2
        for(NSUInteger i = 0; i<n-1; ++i){
            for(NSUInteger j = 0; j<n-i-1; ++j) {
                if ([[[versions objectAtIndex:i] shortenedVersionNumberString] compare:[[versions objectAtIndex:i+1] shortenedVersionNumberString] options:NSNumericSearch] == NSOrderedDescending) { // Swap
                    [versions exchangeObjectAtIndex:i withObjectAtIndex:i+1];
                }
            }
        }
    }
    // Find the best version
    NSInteger index;
    for(NSString *version in versions) {
        index = [self installable:version];
        if(index > 0) return index;
    }
    return -1;
}

// 0 = false, > 0 means true
- (NSUInteger) installable: (NSString *)version {
    NSUInteger index = 1;
    for(ConfigVersion *config in self.availableVersions){
        if([version isEqual:config.version]){
            if([config.macOSVersion installableInCurrentVersion]){
                return index;
            }
        }
        ++index;
    }
    return 0;
}

- (BOOL) newerThanVersion: (NSString *) version {
    if ([[self.currentVersion shortenedVersionNumberString] compare:[version shortenedVersionNumberString] options:NSNumericSearch] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}
@end
