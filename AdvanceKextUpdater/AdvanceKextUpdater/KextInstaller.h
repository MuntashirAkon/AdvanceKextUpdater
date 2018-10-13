//
//  KextInstaller.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 12/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextInstaller_h
#define KextInstaller_h

#import "KextConfig.h"
#import "ConfigBinary.h"
// ------------
// HOW IT WORKS
// ------------
// Gather info:
// 1. Pre-install script (if available)
// 2. Required kext(s) (if necessary)
// 3. Conflicted kext(s) (if required to remove)
// 4. Kext(s) to be installed (if required)
// 5. Post-install script (if available)
// All these info is to be saved in KextHandler.kextTmpPath which will be known as the default folder
// Information of required kext(s) will be saved in the “required“ folder inside the default folder
// Information of conflicted kext(s) will be saved in the “conflicted“ folder inside the default folder
// Scripts will be located in the “scripts” folder inside the default folder
// Procecss: (in a helper tool)
// 1. Run pre-install script
// 2. Install required kext(s)
// 3. Remove conflicted kext(s)
// 4. Install kext
// 5. Run post-install script

@interface KextInstaller : KextConfig {
//    ConfigBinary *bin;
//    BinaryHandler *currentBin;
//    STPrivilegedTask *adminTask;
//    int returnCode; // set after runPreInstallTask is executed
//    NSArray<NSString *> *kexts;
}
@property (strong, nonatomic, readonly) KextConfig *config;

//- (instancetype) initWithConfig: (KextConfig *) config;
- (BOOL) copyAllTo: (NSString *) tmpDir;
- (BOOL) copy: (NSURL *) file to: (NSString *) dir;
//- (int) runPreInstallTask;
//- (id) installRequiredKexts;
//- (id) removeConflictedKexts;
//- (id) installKexts;
//- (id) revertInstallation;
//- (NSString *) runPostInstallTask;

@end

#endif /* KextInstaller_h */
