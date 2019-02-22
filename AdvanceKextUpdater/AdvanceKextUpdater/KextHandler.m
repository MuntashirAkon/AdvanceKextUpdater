//
//  KextHandler.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import "KextHandler.h"
#import "JSONParser.h"
#import "ConfigMacOSVersionControl.h"
#import "Task.h"
#import "utils.h"
#import "KextFinder.h"
#import "KextConfig.h"

// What it does:
// - Loads catalog.json
// - Loads available kexts
// - Loads installed kexts
// - Loads version of the installed kexts
// - Update installed kexts (along with version) after 10 minutes (?)

@implementation KextHandler
+ (id)sharedKextHandler {
    @try{
        static KextHandler *kextHandler = nil;
        static dispatch_once_t dispatch_token;
        dispatch_once(&dispatch_token, ^{
            kextHandler = [KextHandler new];
        });
        return kextHandler;
    } @catch (NSException *e) {
        @throw [NSException exceptionWithName:e.name reason:e.reason userInfo:nil];
    }
}

- (instancetype) init {
    [KextHandler createFilesIfNotExist];
    NSString *path = [KextHandler kextDBPath];
    // Read catalog.json and list kexts
    path = [path stringByAppendingPathComponent:@"catalog"];
    path = [path stringByAppendingPathExtension:@"json"];
    if([NSFileManager.defaultManager fileExistsAtPath:path]){
        catalog = [JSONParser parseFromFile:path];
        kextNames = [catalog allKeys];
        NSMutableArray *kextList = [NSMutableArray array];
        for(NSString *kextName in kextNames){
            [kextList addObject:kextName];
            id kextInfo = [catalog objectForKey:kextName];
            if([kextInfo isKindOfClass:NSDictionary.class]){
                if([kextInfo objectForKey:@"remote_url"] != nil) {
                    [remoteKexts setObject:[NSURL URLWithString:[kextInfo objectForKey:@"remote_url"]] forKey:kextName];
                }
            }
        }
        kexts = kextList;
        return self;
    }
    return nil;
}

+ (NSString *) appPath {
    return isRootUser() ? [NSString stringWithFormat:@"/Users/%@/Library/Application Support/AdvanceKextUpdater", getMainUser()] : [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:APP_NAME];
}

+ (NSString *) appCachePath {
    return isRootUser() ? [NSString stringWithFormat:@"/Users/%@/Library/Caches/AdvanceKextUpdater", getMainUser()] : [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:APP_NAME];
}

+ (NSString *) kextBackupPath {
    return isRootUser() ? [NSString stringWithFormat:@"/Users/%@/Library/Caches/AdvanceKextUpdater/Backups", getMainUser()] : [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:APP_NAME] stringByAppendingPathComponent:@"Backups"];
}

+ (NSString *) PreferencesFile {
    return [self.appPath stringByAppendingPathComponent:@"io.github.muntashirakon.AdvanceKextUpdater.plist"];
}

/**
 * @return Kext database path
 */
+ (NSString *) kextDBPath {
    return [[self appPath] stringByAppendingPathComponent:KEXT_BRANCH];
}

+ (NSString *) kextCachePath {
    return [self.appCachePath stringByAppendingPathComponent:@"kexts"];
}

+ (NSString *) guideCachePath {
    return [self.appCachePath stringByAppendingPathComponent:@"guides"];
}

+ (NSString *) pciIDsCachePath {
    return [self.appCachePath stringByAppendingPathComponent:@"pciids"];
}

+ (NSString *) tmpPath {
    return [@"/tmp" stringByAppendingPathComponent:APP_NAME];
}

+ (NSString *) kextTmpPath {
    return [self.tmpPath stringByAppendingPathComponent:@"kexts"];
}

// lock file exists when tasks is running
+ (NSString *) lockFile {
    return [self.tmpPath stringByAppendingPathComponent:@"lockfile"];
}

+ (NSString *) messageFile {
    return [self.tmpPath stringByAppendingPathComponent:@"message"];
}

+ (NSString *) stdinPath {
    return [self.appPath stringByAppendingPathComponent:@"in"];
}

+ (NSString *) stdoutPath {
    return [self.tmpPath stringByAppendingPathComponent:@"out"];
}

+ (NSString *) stderrPath {
    return self.stdoutPath;
}

+ (NSString *) launchDaemonPlistFile {
    return [[@"/Library/LaunchDaemons/" stringByAppendingPathComponent:launchDaemonName] stringByAppendingPathExtension:@"plist"];
}

/**
 * Fetch latest version from the git repo
 *
 * @return BOOL
 */
+ (BOOL) checkForDBUpdate {
    @try {
        NSString *git_exec = [[NSBundle mainBundle] pathForResource:@"git" ofType:nil];
        NSString *path = [self kextDBPath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            // Clone if not exists
            return [self initDB];
        } else {
            // Update from git
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = git_exec;
            task.arguments = @[@"-C", path, @"pull", @"origin", KEXT_BRANCH];
            [task launch];
            [task waitUntilExit];
            return [task terminationStatus] == 0 ? YES : NO;
        }
    } @catch(NSError *e) {
        return NO;
    }
}

/**
 * Clone from the repo
 *
 * @return BOOL
 */
+ (BOOL) initDB {
    NSString *git_exec = [[NSBundle mainBundle] pathForResource:@"git" ofType:nil];
    @try {
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = git_exec;
        // git clone KEXT_REPO KEXT_PATH
        task.arguments = @[@"clone", @"-b", KEXT_BRANCH, KEXT_REPO, [self kextDBPath]];
        [task launch];
        [task waitUntilExit];
        if(task.terminationStatus == 0) {
            // move to KEXT_BRANCH
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = git_exec;
            task.arguments = @[@"-C", [self kextDBPath], @"checkout", KEXT_BRANCH];
            [task launch];
            [task waitUntilExit];
            return task.terminationStatus == 0 ? YES : NO;
        }
    } @catch(NSError *e) {}
    return NO;
}

- (NSArray<NSString *> *) listKextsWithUpdate {
    NSMutableArray *kextNeedsUpdate = NSMutableArray.array;
    for(NSString *kextName in [self listInstalledKext]){
        if([self needUpdating:kextName]){
            // TODO: Exclude from preferences?
            [kextNeedsUpdate addObject:kextName];
        }
    }
    return kextNeedsUpdate;
}

/**
 * List installed kext based on kext db, search them at SLE and LE (macOS 10.11 or later)
 *
 * @return An array of kexts (with extension)
 */
- (NSArray<NSString *> *) listInstalledKext {
    if(kexts == nil) return nil;
    // TODO: Cache installed kext for later
    NSMutableArray *installedKexts = [NSMutableArray array];
    KextFinder *kf = [KextFinder sharedKextFinder];
    for(NSString *kext in kextNames){
        if([kf isInstalled:kext]) [installedKexts addObject:kext];
    }
    return [installedKexts copy];
}

- (NSArray<NSString *> *) listKext {
    return kexts.copy;
}

- (NSDictionary<NSString *, NSURL *> *) listRemoteKext {
    return remoteKexts.copy;
}

- (BOOL)needUpdating:(NSString *)kextName {
    @try{
        NSString *installedVersion = [KextFinder.sharedKextFinder findVersion:kextName];
        KextConfig *kextConfig = [self kextConfig:kextName];
        return [kextConfig.versions newerThanVersion:installedVersion];
    } @catch (NSException *e) {
        return NO;
    }
}

- (id _Nullable)kextConfig:(NSString *)kextName {
    // Load kext config
    KextConfig *kextConfig;
    if([remoteKexts objectForKey:kextName] != nil) {
        kextConfig = [KextConfig.alloc initWithKextName:kextName URL:[remoteKexts objectForKey:kextName]];
    } else {
        kextConfig = [KextConfig.alloc initWithKextName:kextName];
    }
    // If unable to load any kext
    if(kextConfig == nil) {
        @throw [NSException exceptionWithName:@"Missing config.json!" reason:@"A config.json file determines the Kext behaviors and other configurations, which is somehow missing. You can create a new issue on GitHub if you are interested." userInfo:nil];
        return nil;
    }
    // Find the best version for the running macOS version
    NSInteger best_version = kextConfig.versions.findTheBestVersion;
    if(best_version != -1) kextConfig = [kextConfig.versions.availableVersions objectAtIndex:best_version].config;
    return kextConfig;
}

+(void)createFilesIfNotExist{
    // Create necessary paths
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *appPath = [KextHandler appPath];
    if(![fm fileExistsAtPath:appPath]){
        if(![fm createDirectoryAtPath:appPath withIntermediateDirectories:YES attributes:nil error:nil]){
            @throw [NSException exceptionWithName:@"Application Support isn't accessible!" reason:@"Creating an important directory at Application Support directory failed!" userInfo:nil];
        }
    }
    [fm createDirectoryAtPath:KextHandler.kextCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.guideCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.kextTmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.kextBackupPath withIntermediateDirectories:YES attributes:nil error:nil];
    if(![fm fileExistsAtPath:KextHandler.kextDBPath]) {
        @throw [NSException exceptionWithName:@"Updating Kext database failed!" reason:@"Failed to update kext database, please check your internet connection and try again." userInfo:nil];
    }
}
@end
