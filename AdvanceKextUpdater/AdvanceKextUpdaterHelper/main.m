//
//  main.m
//  AdvanceKextUpdaterHelper
//
//  Created by Muntashir Al-Islam on 13/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdlib.h>
#import "../AdvanceKextUpdater/utils.h"
#import "../AdvanceKextUpdater/KextHandler.h"
#import "../AdvanceKextUpdater/ConfigMacOSVersionControl.h"
#import "KextAction.h"

#define ACTION_STDIN 1 // Read arguments from STDIN
#define ACTION_ARGV  2 // Read arguments from argv[]
#define ACTION_FILE  3 // Read arguments from file

#define ACTION_DEFAULT ACTION_STDIN // Default action

/// @function _return
///
/// @abstract
/// Remove lockfile and unload the launch daemon as the program exits
///
/// @param ret_value
/// The value to be returned on exit to the OS
///
/// @return
/// The return value supplied as agrument
///
int _return(int ret_value){
    // Delete lock file
    [NSFileManager.defaultManager removeItemAtPath:KextHandler.lockFile error:nil];
    // Unload the launch agent
    tty([NSString stringWithFormat:@"launchctl unload %@", KextHandler.launchDaemonPlistFile], nil);
    if(tty([NSString stringWithFormat:@"chown -R %@:wheel '%@'", getMainUser(), KextHandler.tmpPath], nil) != EXIT_SUCCESS) _fprintf(stderr, @"Cannot chown");
    return ret_value;
}

void _status(NSString *msg){
    FILE *fp = fopen(KextHandler.lockFile.UTF8String, "w");
    _fprintf(fp, msg);
    fclose(fp);
}

/// @function _message
///
/// @abstract
/// Display final message to the user
///
/// @param status_code
/// The status code (0 = true, 1 = false)
///
/// @param msg
/// The message containing the details of the status
///
void _message(int status_code, NSString * _Nonnull msg){
    FILE *fp = fopen(KextHandler.messageFile.UTF8String, "w");
    _fprintf(fp, [NSString stringWithFormat:@"%d\n%@", status_code, msg]);
    fclose(fp);
}

// Arguments TODO: Merge them with HelperController
#define ARG_AUTO    @"auto_update"
#define ARG_INSTALL @"install"
#define ARG_UPDATE  @"update"
#define ARG_REMOVE  @"remove"
#define ARG_CACHE   @"rebuildcache"
#define ARG_PERM    @"repairpermissions"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
#if 1
        if(!isRootUser()){
            fprintf(stderr, "Helper tool must be run as root!\n");
            return _return(1);
        }
#endif

// Get the arguments in the "args" array
#if ACTION_DEFAULT == ACTION_STDIN // Get from stdin
        NSString *arg = [[NSString.alloc initWithData:NSFileHandle.fileHandleWithStandardInput.availableData encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray<NSString *> *args = [arg componentsSeparatedByString:@" "];
#elif ACTION_DEAULT == ACTION_FILE // Get from file
        // Analyse arguments
        NSError *error;
        NSString *arg = [[NSString stringWithContentsOfFile:KextHandler.stdinPath encoding:NSUTF8StringEncoding error:&error] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(error) {
            fprintf(stderr, "Error reading arguments!\n");
            return _return(1);
        }
        NSArray<NSString *> *args = [arg componentsSeparatedByString:@" "];
#elif ACTION_DEAULT == ACTION_ARGV // Get from argv
        NSMutableArray<NSString *> *args = NSMutableArray.array;
        for(int i = 1; i<argc; ++i)
            [args addObject:[NSString stringWithUTF8String:argv[i]];
#endif
        if(args.count < 1) {
            fprintf(stderr, "Error reading arguments!\n");
            return _return(1);
        }
        // Handle agruments
        NSString *verb = [args objectAtIndex:0];
#ifdef DEBUG
             _fprintf(stderr, @"Service ran with verb '%@'\n", verb);
#endif
        @try {
        if([verb isEqualToString:ARG_INSTALL]){
            if(args.count == 2){
                [[KextInstall.alloc initWithKext:[args objectAtIndex:1]] doAction];
            } else {
                _fprintf(stderr, @"Too few arguments supplied!\n", verb);
                return _return(1);
            }
        } else if ([verb isEqualToString:ARG_UPDATE]){
            if(args.count == 2){
                [[KextUpdate.alloc initWithKext:[args objectAtIndex:1]] doAction];
            } else {
                _fprintf(stderr, @"Too few arguments supplied!\n", verb);
                return _return(1);
            }
        } else if ([verb isEqualToString:ARG_REMOVE]){
            if(args.count == 2){
                [[KextRemove.alloc initWithKext:[args objectAtIndex:1]] doAction];
            } else {
                _fprintf(stderr, @"Too few arguments supplied!\n", verb);
                return _return(1);
            }
        } else if ([verb isEqualToString:ARG_CACHE]){
#ifdef DEBUG
            _fprintf(stderr, @"== Rebuilding Cache ==\n");
#endif
            @try {
                int ret_val;
                if([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11){ // For 10.11 or later
                    ret_val = tty(@"/usr/sbin/kextcache -i /", nil);
                } else { // For 10.10 or earlier
                    ret_val = tty([NSString stringWithFormat:@"/usr/bin/touch %@;/usr/sbin/kextcache -Boot -U /", kSLE], nil);
                }
                if(ret_val == EXIT_SUCCESS){
                    _message(EXIT_SUCCESS, @"Kernel cache was rebuilt successfully!");
                    return _return(EXIT_SUCCESS);
                } else {
                    _message(EXIT_FAILURE, @"Failed to rebuild kernel cache!");
                    return _return(EXIT_FAILURE);
                }
            } @catch (NSError *e) {
                _message(EXIT_FAILURE, [e.userInfo objectForKey:@"details"]);
                return _return(EXIT_FAILURE);
            }
        } else if ([verb isEqualToString:ARG_PERM]){
#ifdef DEBUG
            _fprintf(stderr, @"== Repairing permissions ==\n");
#endif
            @try {
                NSString *command = [NSString stringWithFormat:@"/bin/chmod -RN %@;/usr/bin/find %@ -type d -print0 | /usr/bin/xargs -0 /bin/chmod 0755;/usr/bin/find %@ -type f -print0 | /usr/bin/xargs -0 /bin/chmod 0644;/usr/sbin/chown -R 0:0 %@;/usr/bin/xattr -cr %@", kSLE, kSLE, kSLE, kSLE, kSLE];
                if([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11){
                    // Also repair permissions for LE if macOS versions is gte 10.11
                    command = [NSString stringWithFormat:@"%@;/bin/chmod -RN %@;/usr/bin/find %@ -type d -print0 | /usr/bin/xargs -0 /bin/chmod 0755;/usr/bin/find %@ -type f -print0 | /usr/bin/xargs -0 /bin/chmod 0644;/usr/sbin/chown -R 0:0 %@;/usr/bin/xattr -cr %@", command, kLE, kLE, kLE, kLE, kLE];
                }
                int ret_val = tty(command, nil);
                if(ret_val == EXIT_SUCCESS){
                    _message(EXIT_SUCCESS, @"Successfully repaired permissions!");
                    return _return(EXIT_SUCCESS);
                } else {
                    _message(EXIT_FAILURE, @"Failed to repair permissions!");
                    return _return(EXIT_FAILURE);
                }
            } @catch (NSError *e) {
                _message(EXIT_FAILURE, [e.userInfo objectForKey:@"details"]);
                return _return(EXIT_FAILURE);
            }
        } else if ([verb isEqualToString:ARG_AUTO]){
#ifdef DEBUG
            _fprintf(stderr, @"== Auto updating ==\n");
#endif
            NSArray<NSString *> *kextsNeedUpdate = [KextHandler.sharedKextHandler listKextsWithUpdate];
            NSMutableArray *failedKexts = NSMutableArray.array;
#ifdef DEBUG
            _fprintf(stderr, @"Needs update %@\n", kextsNeedUpdate);
#endif
            if(hasInternetConnection()){
                for(NSString *kext in kextsNeedUpdate){
                    if(![[KextUpdate.alloc initWithKext:kext] doAction]){
                        [failedKexts addObject:kext];
                    }
                }
                if(failedKexts.count > 0){
                    _message(EXIT_FAILURE, [NSString stringWithFormat:@"Failed to update %@.", [failedKexts componentsJoinedByString:@", "]]);
#ifdef DEBUG
                    _fprintf(stderr, @"Failed to update %@\n", failedKexts);
#endif
                    return _return(EXIT_FAILURE);
                }
            } else {
#ifdef DEBUG
                _fprintf(stderr, @"Aborted since no internet connection is detected.\n", kextsNeedUpdate);
#endif
                return _return(EXIT_FAILURE);
            }
        } else {
            _fprintf(stderr, @"Unknown verb (%@)!\n", verb);
            return _return(1);
        }
        } @catch (NSError *e){
            return _return(1);
        } @catch (NSException *e){
            return _return(1);
        }
    }
    return _return(0);
}
