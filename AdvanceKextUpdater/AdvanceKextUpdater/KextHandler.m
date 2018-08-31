//
//  KextHandler.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextHandler.h"
#import "JSONParser.h"
#import "ConfigMacOSVersionControl.h"
#import "Task.h"

@implementation KextHandler
- (instancetype) init {
    NSString *path = [KextHandler kextDBPath];
    // Read catalog.json and list kexts
    path = [path stringByAppendingPathComponent:@"catalog"];
    path = [path stringByAppendingPathExtension:@"json"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSDictionary *catalog = [JSONParser parseFromFile:path];
        kextNames = [catalog allKeys];
        NSMutableArray *kextList = [NSMutableArray array];
        for(NSString *kextName in kextNames){
            [kextList addObject:[kextName stringByAppendingPathExtension:@"kext"]];
        }
        kexts = kextList;
        // TODO: handle remote_url
    } else {
        kexts = nil;
    }
    return self;
}

+ (NSString *) appPath {
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:APP_NAME];
}

+ (NSString *) appCachePath {
    return [[self appPath] stringByAppendingPathComponent:@"Cache"];
}

/**
 * @return Kext database path
 */
+ (NSString *) kextDBPath {
    return [[self appPath] stringByAppendingPathComponent:KEXT_BRANCH];
}

+ (NSString *) kextCachePath {
    return [[[self appPath] stringByAppendingPathComponent:@"Cache"] stringByAppendingPathComponent:@"kexts"];
}

+ (NSString *) guideCachePath {
    return [[[self appPath] stringByAppendingPathComponent:@"Cache"] stringByAppendingPathComponent:@"guides"];
}

+ (NSString *) kextTmpPath {
    return [[@"/tmp" stringByAppendingPathComponent:APP_NAME] stringByAppendingPathComponent:@"kexts"];
}

/**
 * Fetch latest version from the git repo
 *
 * @return BOOL
 */
+ (BOOL) checkForDBUpdate {
    NSString *git_exec = [[NSBundle mainBundle] pathForResource:@"git" ofType:nil];
    NSString *path = [self kextDBPath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // Clone if not exists
        return [self initDB];
    } else {
        // Update from git
        @try {
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = git_exec;
            task.arguments = @[@"-C", path, @"pull"];
            [task launch];
            [task waitUntilExit];
            return [task terminationStatus] == 0 ? YES : NO;
        } @catch(NSError *e) {
            return NO;
        }
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
        task.arguments = @[@"clone", KEXT_REPO, [self kextDBPath]];
        [task launch];
        [task waitUntilExit];
        if(task.terminationStatus == 0) {
            // move to KEXT_BRANCH
            task.launchPath = git_exec;
            task.arguments = @[@"checkout", KEXT_BRANCH];
            [task launch];
            [task waitUntilExit];
        }
        return task.terminationStatus == 0 ? YES : NO;
    } @catch(NSError *e) {
        return NO;
    }
}

- (void) checkForKextUpdate {
    // Check for kext update
}

/**
 * List installed kext based on kext db, search them at SLE and LE (macOS 10.11 or later)
 *
 * @return An array of kexts (with extension)
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
    return kexts;
}

- (void) installKext {
    // Install kext at SLE or LE (macOS 10.11 or later)
}

- (void) repairPermissions: (NSArray *) kexts {
    // Repair permission for all or a single kext
}

- (void) updateKernelCache {
    // Update kernel cache
}

@end
