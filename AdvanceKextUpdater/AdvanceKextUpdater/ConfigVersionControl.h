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
@class KextConfig;

@interface ConfigVersion : NSObject {}
@property NSString *version;
@property KextConfig *config;
@property ConfigMacOSVersionControl *macOSVersion;
@end

@interface ConfigVersionControl: NSObject {}
@property NSString *currentVersion;
@property NSArray<ConfigVersion *> *availableVersions; // Actually a stack

- (instancetype) initWithSelfConfig: (KextConfig *) baseConfig andOtherVersions: (id) otherVersions;
@end

#endif /* ConfigVersionControl_h */
