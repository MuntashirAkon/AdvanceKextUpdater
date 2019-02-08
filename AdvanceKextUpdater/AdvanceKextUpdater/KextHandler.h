//
//  KextHandler.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextHandler_h
#define KextHandler_h
#import <Foundation/Foundation.h>

#define KEXT_REPO @"https://github.com/MuntashirAkon/AdvanceKextUpdater.git"
#define KEXT_BRANCH @"kext_db"
#define launchDaemonName @"io.github.muntashirakon.advancekextupdater.helper.agent"

@interface KextHandler: NSObject {
    NSArray<NSString *> *kextNames;
    NSMutableArray<NSString *> *kexts;
    NSDictionary *catalog;
    NSMutableDictionary<NSString *, NSURL *> *remoteKexts; // kextName => remoteURL
}
+ (BOOL) initDB;
+ (BOOL) checkForDBUpdate;
+ (NSString *) appPath;
+ (NSString *) appCachePath;
+ (NSString *) kextBackupPath;
+ (NSString *) kextDBPath;
+ (NSString *) kextCachePath;
+ (NSString *) guideCachePath;
+ (NSString *) pciIDsCachePath;
/// Temporary directory root
/// <code>/tmp/AdvanceKextUpdater</code>
/// @return
/// Temporary directory root
+ (NSString *) tmpPath;
+ (NSString *) kextTmpPath;
+ (NSString *) lockFile;
+ (NSString *) messageFile;
+ (NSString *) stdinPath;
+ (NSString *) stdoutPath;
+ (NSString *) stderrPath;
+ (NSString *) launchDaemonPlistFile;
+ (NSString *) PreferencesFile;
/*!
 * Singleton
 */
+ (id)sharedKextHandler;
- (NSArray<NSString *> *) listInstalledKext;
- (NSArray<NSString *> *) listKext;
- (NSDictionary<NSString *, NSURL *> *) listRemoteKext;
@end
#endif /* KextHandler_h */
