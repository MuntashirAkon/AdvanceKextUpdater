//
//  KextHandler.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextHandler.h"

@implementation KextHandler
- (instancetype) init {
    NSString *path = [KextHandler kextDBPath];
    // Read catalog and list kexts
    
    kexts = nil; // TODO: List kexts from DB
    return self;
}

/**
 * @return Kext database path
 */
+ (NSString *) kextDBPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"AdvanceKextUpdater"];
    path = [path stringByAppendingPathComponent:KEXT_BRANCH];
    return path;
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
 *
 */
- (void) listInstalledKext {
    //
}

- (void) installKext {
    // Install kext at SLE or LE (macOS 10.11 or later)
}

- (void) repairPermission: (BOOL) all {
    // Repair permission for all or a single kext
}

- (void) updateKernelCache {
    // Update kernel cache
}

@end
