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

@end
