//
//  ConfigVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigVersionControl_h
#define ConfigVersionControl_h

#import "ConfigMacOSVersionControl.h"
#import "KextConfig.h"
#import "utils.h"

@class KextConfig;

@interface ConfigVersion : NSObject {}
@property NSString *version;
@property KextConfig *config;
@property ConfigMacOSVersionControl *macOSVersion;
@end

@interface ConfigVersionControl: NSObject {
    NSMutableArray<NSString *> *versions;
}

@property NSString *currentVersion;
@property NSArray<ConfigVersion *> *availableVersions;

- (instancetype) initWithSelfConfig: (KextConfig *) baseConfig andOtherVersions: (id) otherVersions;
- (NSInteger) findTheBestVersion;
- (BOOL) newerThanVersion: (NSString *) version;
@end

#endif /* ConfigVersionControl_h */
