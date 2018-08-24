//
//  ConfigVersionControl.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigVersionControl.h"

@implementation ConfigVersionControl
- (instancetype) init {
    currentVersion = nil;
    availableVersions = nil;
    return self;
}

- (instancetype) initWithVersion: (NSString *) version {
    currentVersion = version;
    availableVersions = nil;
    return self;
}

- (instancetype) initWithVersion: (NSString *) version andOtherVersions: (NSDictionary *) otherVersions{
    currentVersion = version;
    // TODO determine other versions
    availableVersions = nil;
    return self;
}

@end
