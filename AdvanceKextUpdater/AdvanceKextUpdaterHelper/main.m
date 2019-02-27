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
#import "../Shared/helper_args.h"
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
    if(tty([NSString stringWithFormat:@"chown -R %@:wheel '%@'", getMainUser(), KextHandler.tmpPath], nil) != EXIT_SUCCESS) { debugPrint(@"Cannot chown!\n"); }
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

void auto_update(){
    debugPrint(@"== Auto updating ==\n");
    NSArray<NSString *> *kextsNeedUpdate = [KextHandler.sharedKextHandler listKextsWithUpdate];
    NSMutableArray *failedKexts = NSMutableArray.array;
    debugPrint(@"Needs update %@\n", kextsNeedUpdate);
    if(hasInternetConnection()){
        for(NSString *kext in kextsNeedUpdate){
            if(![[KextUpdate.alloc initWithKext:kext] doAction]){
                [failedKexts addObject:kext];
            }
        }
        if(failedKexts.count > 0){
            [NSException exceptionWithName:@"Failed to update some kexts!" reason:[NSString stringWithFormat:@"Failed to update %@.", [failedKexts componentsJoinedByString:@", "]] userInfo:nil];
            _message(EXIT_FAILURE, [NSString stringWithFormat:@"Failed to update %@.", [failedKexts componentsJoinedByString:@", "]]);
        }
    } else {
        [NSException exceptionWithName:@"Update aborted!" reason:@"Update aborted since no internet connection is detected!" userInfo:nil];
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
#if 1
        if(!isRootUser()){
            debugPrint(@"Helper tool must be run as root!\n");
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
            debugPrint(@"Error reading arguments!\n");
            return _return(1);
        }
        NSArray<NSString *> *args = [arg componentsSeparatedByString:@" "];
#elif ACTION_DEAULT == ACTION_ARGV // Get from argv
        NSMutableArray<NSString *> *args = NSMutableArray.array;
        for(int i = 1; i<argc; ++i)
            [args addObject:[NSString stringWithUTF8String:argv[i]];
#endif
        if(args.count < 1) {
            debugPrint(@"Error reading arguments!\n");
            return _return(1);
        }
        // Handle agruments
        AKUHelperArgs verb = [args objectAtIndex:0].intValue;
        debugPrint(@"Service ran with verb '%u'\n", verb);
        @try {
            switch(verb){
                case AKUHelperArgAutoUpdate:
                    auto_update();
                    break;
                case AKUHelperArgInstall:
                    if(args.count == 2){
                        [[KextInstall.alloc initWithKext:[args objectAtIndex:1]] doAction];
                    } else {
                        debugPrint(@"Too few arguments supplied!\n");
                        return _return(1);
                    }
                    break;
                case AKUHelperArgRebuildCache:
                    debugPrint(@"== Rebuilding Cache ==\n");
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
                    break;
                case AKUHelperArgRepairPermissions:
                    debugPrint(@"== Repairing permissions ==\n");
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
                    break;
                case AKUHelperArgRemove:
                    if(args.count == 2){
                        [[KextRemove.alloc initWithKext:[args objectAtIndex:1]] doAction];
                    } else {
                        debugPrint(@"Too few arguments supplied!\n");
                        return _return(1);
                    }
                    break;
                case AKUHelperArgUpdate:
                    if(args.count == 2){
                        [[KextUpdate.alloc initWithKext:[args objectAtIndex:1]] doAction];
                    } else {
                        debugPrint(@"Too few arguments supplied!\n");
                        return _return(1);
                    }
                    break;
                default:
                    debugPrint(@"Unknown verb (%@)!\n", verb);
                    return _return(1);
            }
        }@catch (NSException *e){
            debugPrint(@"Error: %@\n", e.name);
            _message(EXIT_FAILURE, e.reason);
            return _return(1);
        }
    }
    return _return(0);
}
