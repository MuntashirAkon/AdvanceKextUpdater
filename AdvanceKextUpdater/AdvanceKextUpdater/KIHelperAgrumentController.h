//
//  KIHelperAgrumentController.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 13/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KIHelperAgrumentController_h
#define KIHelperAgrumentController_h

// USAGE: <verb> [..]
// Verbs with args:
// install <kextName> - install a kext
// update <kextName> - update a kext
// remove <kextName> - remove/uninstall a kext
// rebuildcache - Rebuild kernel cache
// repairpermissions - Repair permissions

@interface KIHelperAgrumentController : NSObject

+ (BOOL) install: (NSString *) kextName;
+ (BOOL) update: (NSString *) kextName;
+ (BOOL) remove: (NSString *) kextName;
+ (BOOL) rebuildCache;
+ (BOOL) repairPermissions;
@end

#endif /* KIHelperAgrumentController_h */
