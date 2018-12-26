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

@implementation KextHandler
- (instancetype) init {
    NSString *path = [KextHandler kextDBPath];
    // Read catalog.json and list kexts
    path = [path stringByAppendingPathComponent:@"catalog"];
    path = [path stringByAppendingPathExtension:@"json"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        catalog = [JSONParser parseFromFile:path];
        kextNames = [catalog allKeys];
        NSMutableArray *kextList = [NSMutableArray array];
        for(NSString *kextName in kextNames){
            [kextList addObject:[kextName stringByAppendingPathExtension:@"kext"]];
            id kextInfo = [catalog objectForKey:kextName];
            if([kextInfo isKindOfClass:NSDictionary.class]){
                if([kextInfo objectForKey:@"remote_url"] != nil) {
                    [remoteKexts setObject:[NSURL URLWithString:[kextInfo objectForKey:@"remote_url"]] forKey:kextName];
                }
            }
        }
        kexts = kextList;
        // TODO: handle remote_url
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
    return [self.tmpPath stringByAppendingPathComponent:@"in"];
}

+ (NSString *) stdoutPath {
    return [self.tmpPath stringByAppendingPathComponent:@"out"];
}

+ (NSString *) stderrPath {
    return self.stdoutPath;
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

- (void) checkForKextUpdate {
    // Check for kext update
}

/**
 * List installed kext based on kext db, search them at SLE and LE (macOS 10.11 or later)
 *
 * @return An array of kexts (with extension)
 * @todo Use `kextfind -no-paths` to get the list
 */
- (NSArray<NSString *> *) listInstalledKext {
    if(kexts == nil) return nil;
    // TODO: Cache installed kext for later
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *kextList = [fm contentsOfDirectoryAtPath:kSLE error:nil];
    NSMutableArray *installedKexts = [NSMutableArray array];
    // Also from LE if macOS version is greater than 10.10
    if([ConfigMacOSVersionControl getMacOSVersionInInt] > 10){
        NSArray *listAtLE = [fm contentsOfDirectoryAtPath:kLE error:nil];
        kextList = [kextList arrayByAddingObjectsFromArray:listAtLE];
    }
    for(NSString *kext in kextList){
        if([kexts indexOfObject:kext] != NSNotFound)
            [installedKexts addObject:kext];
    }
    return [installedKexts copy];
}

- (NSArray<NSString *> *) listKext {
    return kexts.copy;
}

- (NSDictionary<NSString *, NSURL *> *) listRemoteKext {
    return remoteKexts.copy;
}
@end
