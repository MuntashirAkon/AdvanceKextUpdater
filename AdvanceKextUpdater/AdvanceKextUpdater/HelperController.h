//
//  HelperController.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 20/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Windows/Spinner.h"

NS_ASSUME_NONNULL_BEGIN

// USAGE: <verb> [..]
// Verbs with args:
// install <kextName> - install a kext
// update <kextName> - update a kext
// update <kextName ...> - update kexts
// remove <kextName> - remove/uninstall a kext
// rebuildcache - Rebuild kernel cache
// repairpermissions - Repair permissions

@interface HelperController : NSObject
@property NSString *launchDaemonFile;
@property BOOL taskStarted;
@property BOOL taskEnded;

+ (instancetype) sharedHelper;

- (BOOL) install: (NSString *) kextName;
- (BOOL) update: (NSString *) kextName;
- (BOOL) batchUpdate: (NSArray<NSString *> *) kextNames;
- (BOOL) remove: (NSString *) kextName;
- (BOOL) rebuildCache;
- (BOOL) repairPermissions;

// Task info
- (BOOL) isTaskRunning;
- (NSString * _Nullable) getLastMessage;
- (NSDictionary * _Nullable) getFinalMessage;
@end

NS_ASSUME_NONNULL_END
