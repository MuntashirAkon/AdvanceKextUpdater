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
+ (NSString * _Nonnull) appPath;
+ (NSString * _Nonnull) appCachePath;
+ (NSString * _Nonnull) kextBackupPath;
+ (NSString * _Nonnull) kextDBPath;
+ (NSString * _Nonnull) kextCachePath;
+ (NSString * _Nonnull) guideCachePath;
+ (NSString * _Nonnull) pciIDsCachePath;
/// Temporary directory root
/// <code>/tmp/AdvanceKextUpdater</code>
/// @return
/// Temporary directory root
+ (NSString * _Nonnull) tmpPath;
+ (NSString * _Nonnull) kextTmpPath;
+ (NSString * _Nonnull) lockFile;
+ (NSString * _Nonnull) messageFile;
+ (NSString * _Nonnull) stdinPath;
+ (NSString * _Nonnull) stdoutPath;
+ (NSString * _Nonnull) stderrPath;
+ (NSString * _Nonnull) launchDaemonPlistFile;
+ (NSString * _Nonnull) PreferencesFile;
+ (void) createFilesIfNotExist;
/*!
 * Singleton
 */
+ (id _Nonnull)sharedKextHandler;
- (NSArray<NSString *> * _Nullable) listInstalledKext;
- (NSArray<NSString *> * _Nullable) listKext;
- (NSDictionary<NSString *, NSURL *> * _Nonnull) listRemoteKext;
- (NSArray<NSString *> * _Nullable) listKextsWithUpdate;
- (BOOL)needUpdating:(NSString * _Nonnull)kextName;
- (BOOL)existsInDB:(NSString * _Nonnull)kextName;
- (id _Nullable) kextConfig:(NSString * _Nonnull)kextName;
@end
#endif /* KextHandler_h */
