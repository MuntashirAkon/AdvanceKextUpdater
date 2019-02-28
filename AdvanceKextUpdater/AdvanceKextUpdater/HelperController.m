//
//  HelperController.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 20/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "HelperController.h"
#import "KextHandler.h"
#import "Task.h"
#import "utils.h"
#import "../Shared/helper_args.h"

@implementation HelperController
@synthesize async;
+ (instancetype)sharedHelper {
    static HelperController *helper = nil;
    static dispatch_once_t dispatch_token;
    dispatch_once(&dispatch_token, ^{
        helper = [HelperController new];
    });
    return helper;
}

- (id) init{
    @try{
        async = NO;
        if (![NSFileManager.defaultManager fileExistsAtPath:KextHandler.launchDaemonPlistFile]) {
            _launchDaemonFile = [[KextHandler.appCachePath stringByAppendingPathComponent:launchDaemonName] stringByAppendingPathExtension:@"plist"];
            NSDictionary *plist = @{
                @"Label": launchDaemonName,
                @"Program": [NSBundle.mainBundle pathForResource:@"AdvanceKextUpdaterHelper" ofType:nil],
                @"RunAtLoad": @YES,
                @"WorkingDirectory": KextHandler.tmpPath,
                @"StandardInPath": KextHandler.stdinPath,
                @"StandardOutPath": KextHandler.stdoutPath,
                @"StandardErrorPath": KextHandler.stderrPath
            };
            if(![plist writeToFile:_launchDaemonFile atomically:YES])
                @throw [NSException exceptionWithName:@"Failed creating launch daemon" reason:@"Launch daemon file to run helper could not be created" userInfo:nil];
        }
    } @catch (NSException *e) {
#ifdef DEBUG
        NSLog(@"%@: %@", e.name, e.reason);
#endif
    }
    return self;
}

- (BOOL) install: (NSString *) kextName {
    return [self runWithArg:[NSString stringWithFormat:@"%u %@", AKUHelperArgInstall, kextName]];
}

- (BOOL) update: (NSString *) kextName {
    return [self runWithArg:[NSString stringWithFormat:@"%u %@", AKUHelperArgUpdate, kextName]];
}

- (BOOL) autoUpdate {
    return [self runWithArg:[NSString stringWithFormat:@"%u", AKUHelperArgAutoUpdate]];
}

- (BOOL) remove: (NSString *) kextName {
    return [self runWithArg:[NSString stringWithFormat:@"%u %@", AKUHelperArgRemove, kextName]];
}

- (BOOL) rebuildCache {
    return [self runWithArg:[NSString stringWithFormat:@"%u", AKUHelperArgRebuildCache]];
}

- (BOOL) repairPermissions {
    return [self runWithArg:[NSString stringWithFormat:@"%u", AKUHelperArgRepairPermissions]];
}

- (BOOL) runTask {
    // Create the lockfile
    if(![NSFileManager.defaultManager createFileAtPath:KextHandler.lockFile contents:[@"Checking..." dataUsingEncoding:NSUTF8StringEncoding] attributes:nil])
        @throw [NSException exceptionWithName:@"Lockfile creation failed!" reason:@"Failed to create the lock file. Please try again or report us." userInfo:nil];
    //
    // Copy and Load the launch agent
    //
    @try{
        if (![NSFileManager.defaultManager fileExistsAtPath:KextHandler.launchDaemonPlistFile]) {
            // Copy & load
            NSString *launchDaemonsRootDir = @"/Library/LaunchDaemons/";
            [AScript adminExec:[NSString stringWithFormat:@"cp %@ %@ && launchctl load %@", _launchDaemonFile, launchDaemonsRootDir, KextHandler.launchDaemonPlistFile]];
        } else {
            // Launch daemon already exist, simply load it
            [AScript adminExec:[NSString stringWithFormat:@"launchctl load %@", KextHandler.launchDaemonPlistFile]];
        }
        if(async){
            // Awake until the task is completed
//        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//        int lockfile = open([KextHandler.lockFile UTF8String], O_EVTONLY);
//        __block dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, lockfile, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE, queue);
//        dispatch_source_set_event_handler(source, ^{
//            unsigned long flags = dispatch_source_get_data(source);
//            if(flags & DISPATCH_VNODE_DELETE) {
//                dispatch_source_cancel(source);
//                // TODO: Store final message
//            } else {
//            // TODO: Update message
//            }
//        });
//        dispatch_source_set_cancel_handler(source, ^(void){
//            close(lockfile);
//        });
//        dispatch_resume(source);
            // Workaround since the above doesn't always work
            while ([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]) {
                sleep(1);
            }
            async = false; // Reset async
        }
    } @catch (NSError *e){
#ifdef DEBUG
        NSLog(@"HelperController::RunTask: %@", [e.userInfo objectForKey:@"details"]);
#endif
        @throw [NSException exceptionWithName:@"Operation failed!" reason:[e.userInfo objectForKey:@"details"] userInfo:nil];
    }
    return YES;
}


- (BOOL) runWithArg: (NSString *) arg {
    // Do not proceed if another task running
    if([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]){
        @throw [NSException exceptionWithName:@"Invalid request!" reason:@"A process is already running, wait until it is finished." userInfo:nil];
        return NO;
    }
    return [arg writeToFile:KextHandler.stdinPath atomically:YES encoding:NSUTF8StringEncoding error:nil] && [self runTask];
}

- (BOOL) isTaskRunning {
    if([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]) return YES;
    return NO;
}

- (NSString * _Nullable) getLastMessage {
    if(![self isTaskRunning]) return nil;
    @try {
        NSString *message = [NSString stringWithContentsOfFile:KextHandler.lockFile encoding:NSUTF8StringEncoding error:nil];
        if(!isNull(message)) return message;
    } @catch (NSError *e) {}
    return nil;
}

- (NSDictionary * _Nullable) getFinalMessage {
    if(![self isTaskRunning]){
        NSString *messageStr = [NSString stringWithContentsOfFile:KextHandler.messageFile encoding:NSUTF8StringEncoding error:nil];
        if(!isNull(messageStr)){
            NSArray *messageArr = [messageStr componentsSeparatedByString:@"\n"];
            if(messageArr.count >= 1){
                return @{
                    @"status": [NSNumber numberWithUnsignedInteger:[[messageArr objectAtIndex:0] intValue]],
                    @"message": [messageArr objectAtIndex:1]
                };
            }
        }
        return @{
            @"status": [NSNumber numberWithUnsignedInteger:EXIT_FAILURE],
            @"message": @"Failed executing the task. Please, try again."
        };
    }
    return nil;
}

- (void) resetTask {
    [NSFileManager.defaultManager removeItemAtPath:KextHandler.lockFile error:nil];
}

@end
