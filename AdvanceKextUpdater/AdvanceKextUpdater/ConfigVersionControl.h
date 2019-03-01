//
//  ConfigVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigVersionControl_h
#define ConfigVersionControl_h

#import <Foundation/Foundation.h>
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

/**
 * @abstract
 * Initialize version control
 * @param baseConfig
 * The main config.json file (parsed using KextConfig)
 * @param otherVersions
 * config-*.json for other versions config.versions, should be an NSArray.
 * @return
 * An object instance of ConfigVersionControl
 */
- (instancetype) initWithSelfConfig: (KextConfig *) baseConfig andOtherVersions: (id) otherVersions;
/**
 * @abstract
 * Finds the best version of the kext for the current macOS
 * @return NSNotFound for none, positive integer if avialable
 */
- (NSInteger) findTheBestVersion;
/**
 * @abstract
 * If the current version is newer (latest) than the given version
 * @param version
 * Version to compare the current version with
 * @return
 * Whether the current version is the latest version
 */
- (BOOL) newerThanVersion: (NSString *) version;
@end

#endif /* ConfigVersionControl_h */
