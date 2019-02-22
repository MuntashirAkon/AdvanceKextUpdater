//
//  KextAction.m
//  AdvanceKextUpdaterHelper
//
//  Created by Muntashir Al-Islam on 24/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextAction.h"
#import "../AdvanceKextUpdater/utils.h"
#import "../AdvanceKextUpdater/Task.h"

#pragma KextAction
@implementation KextAction
/// @param kextName Full kext name ie. with extension
- (instancetype) initWithKext: (NSString *) kextName {
    self->kextName = kextName;
    kextFinder = [KextFinder sharedKextFinder];
    preference = [PreferencesHandler sharedPreferences];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyyMMdd"];
    backupLocation = [NSString stringWithFormat:@"%@/%@", KextHandler.kextBackupPath, [formatter stringFromDate:[NSDate date]]];
    if(![NSFileManager.defaultManager fileExistsAtPath:backupLocation]){
        [NSFileManager.defaultManager createDirectoryAtPath:backupLocation withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}
- (BOOL) doAction {
    // Implement this on every child classes
    return NO;
}

+ (BOOL) load: (NSString *) kextLocation {
    if(tty([NSString stringWithFormat:@"kextload %@", kextLocation], nil) == EXIT_SUCCESS)
        return YES;
    return NO;
}
+ (BOOL) unload: (NSString *) kextLocation {
    if(tty([NSString stringWithFormat:@"kextunload %@", kextLocation], nil) == EXIT_SUCCESS)
        return YES;
    return NO;
}
- (BOOL) removeKext: (NSString *) kextName {
    NSArray<NSString *> *kextLocations = [kextFinder findLocations:kextName];
    BOOL backed_up = !preference.kexts.backup; // Little bit of hack to backup the removed kext!
    BOOL remove_non_systems = preference.kexts.anywhere;
    NSFileManager *fm = NSFileManager.defaultManager;
    for(NSString *kextLocation in kextLocations){
        if([fm fileExistsAtPath:kextLocation]) {
#ifdef DEBUG
            _fprintf(stderr, @" Removing %@: ", kextLocation);
#endif
            if(!remove_non_systems && !([kextLocation hasPrefix:kSLE] || [kextLocation hasPrefix:kLE])){
#ifdef DEBUG
                _fprintf(stderr, @"Skipped\n");
#endif
                continue;
            }
            [KextAction unload:kextLocation]; // Don't care about the return value
            if(backed_up){
                if(tty([NSString stringWithFormat:@"rm -Rf '%@'", kextLocation], nil) != EXIT_SUCCESS) {
#ifdef DEBUG
                    _fprintf(stderr, @"Couldn't remove!\n");
#endif
                    return NO;
                } else {
                    tty([NSString stringWithFormat:@"chown -R %@:staff '%@'", getMainUser(), KextHandler.kextBackupPath], nil);
#ifdef DEBUG
                    _fprintf(stderr, @"Backed up & removed\n");
#endif
                }
            } else {
                if(tty([NSString stringWithFormat:@"mv '%@' '%@'", kextLocation, backupLocation], nil) != EXIT_SUCCESS) {
#ifdef DEBUG
                    _fprintf(stderr, @"Couldn't remove!\n");
#endif
                    return NO;
                }
#ifdef DEBUG
                else {
                    _fprintf(stderr, @"Removed\n");
                }
#endif
            }
        }
    }
    [kextFinder updateList];
    return YES;
}

+ (void) status:(NSString *) msg {
    FILE *fp = fopen(KextHandler.lockFile.UTF8String, "w");
    _fprintf(fp, msg);
    fclose(fp);
}

///
/// Display final message to the user
/// @param status_code The status code (0 = true, 1 = false)
/// @param msg The message containing the details of the status
///
+ (void) message:(NSString * _Nullable) msg withStatusCode:(int) status_code {
    if(msg == nil){
        if(status_code == EXIT_SUCCESS) {
            msg = @"The kext was installed successfully!";
        } else {
            msg = @"Sorry, the kext couldn't be installed!";
        }
    }
    FILE *fp = fopen(KextHandler.messageFile.UTF8String, "w");
    _fprintf(fp, [NSString stringWithFormat:@"%d\n%@", status_code, msg]);
    fclose(fp);
}
@end

#pragma KextInstall
@implementation KextInstall
- (instancetype) initWithKext: (NSString *) kextName {
    if([super initWithKext:kextName]){
        self->config = [KextConfig.alloc initWithKextName:kextName];
        return self;
    }
    return nil;
}
- (BOOL) downloadRequirments {
    BinaryHandler *current = config.binaries.recommended;
    NSString *kextPath = [KextHandler.kextTmpPath stringByAppendingPathComponent:config.kextName];
    [KextInstall create:kextPath];
    NSString *zipFile = [[kextPath stringByAppendingPathComponent:@"Kext"] stringByAppendingPathExtension:@"zip"];
    targetFolder = [kextPath stringByAppendingPathComponent:@"Kext"];
    if([NSFileManager.defaultManager fileExistsAtPath:targetFolder]){
        [NSFileManager.defaultManager removeItemAtPath:targetFolder error:nil];
    }
    if(current.location != nil){ // Requested downloading the binary file
        // Download zip
        if([URLTask get:[NSURL URLWithString:current.url] toFile:zipFile supress:YES]){
            // Extract and save it to somewhere else
            if([KextInstall unzip:zipFile to:targetFolder]){
                return YES;
            }
        }
    }
    return NO;
}
- (BOOL) removeConflicts {
    NSArray<ConfigConflictKexts *> *kexts = config.conflict;
    for(ConfigConflictKexts *kext in kexts) {
        // If version is matched, remove it
        @try{
            NSString *version = [kextFinder findVersion:kext.kextName];
            NSComparisonResult result = kext.uptoLatest ? NSOrderedDescending : NSOrderedSame;
            if([kext.version isEqual:@"*"] || [version.shortenedVersionNumberString compare:kext.version options:NSNumericSearch] == result){
                if(![self removeKext:kext.kextName]) return NO;
            }
        } @catch (NSException *e) { continue; } // Not installed
    }
    return YES;
}
- (BOOL) installRequirements {
    NSArray<ConfigRequiredKexts *> *kexts = config.requirments;
    for(ConfigRequiredKexts *kext in kexts) {
        @try{
            NSString *version = [kextFinder findVersion:kext.kextName];
#ifdef DEBUG
            _fprintf(stderr, @"%@ (%@): ", kext.kextName, version);
#endif
            NSComparisonResult result = kext.uptoLatest ? NSOrderedDescending : NSOrderedSame;
            if(![kext.version isEqual:@"*"] && [version.shortenedVersionNumberString compare:kext.version options:NSNumericSearch] != result){
#ifdef DEBUG
                _fprintf(stderr, @"Need updating.\n");
#endif
                if(![[KextUpdate.alloc initWithKext:kext.kextName] doAction]) {// Update kext
                    return NO;
                }
            }
#ifdef DEBUG
            else {
                _fprintf(stderr, @"No need to update.\n");
            }
#endif
        } @catch (NSException *e){
            if(![[KextInstall.alloc initWithKext:kext.kextName] doAction]) {// Install kext
                return NO;
            }
#ifdef DEBUG
            _fprintf(stderr, @"%@: Need installing (%@)\n", kext.kextName, e.reason);
#endif
        }
    }
    return YES;
}
- (BOOL) runPreInstallTask {
    BinaryHandler *current = config.binaries.recommended;
    if(current.script != nil){
        NSString *output;
        int status = tty([NSString stringWithFormat:@"bash '%@' '%@'", current.script, current.url], &output);
        NSArray<NSString *> *kexts;
        switch (status) {
            case 0:
                return YES;
            case 1:
                kexts = [output componentsSeparatedByString:@"\n"];
                for(NSString *kext in kexts){
                    if(![KextInstall copy:kext to:config.target.target]){
                        @throw [NSException exceptionWithName:@"KextInstallException" reason:@"Some kext(s) couldn't be copied into their places." userInfo:nil];
                        return NO;
                    }
                }
                return YES;
            case 2:
                @throw [NSException exceptionWithName:@"KextInstallException" reason:output userInfo:nil];
                return NO;
        }
    }
    return NO;
}
- (BOOL) installKext {
    BinaryHandler *current = config.binaries.recommended;
    if(current.location != nil){
        // Copy them to kSLE or kLE
        NSString *kextPath =[NSString stringWithFormat:@"%@/%@", targetFolder, current.location];
        if([KextInstall copy:kextPath to:config.target.target]){
            // Load the kext
            [KextAction load:[NSString stringWithFormat:@"%@/%@", config.target.target, config.kextName]];
            // Copy to Clover directories
            if(preference.clover.support){
                for(NSString *kextLocation in preference.clover.directories){
                    [KextInstall copy:kextPath to:kextLocation];
                    tty([NSString stringWithFormat:@"/usr/sbin/chown -R 0:0 %@/%@", kextLocation, config.kextName], nil);
                }
            }
            return YES;
        }
    }
    return NO;
}
- (NSString * _Nullable) runPostInstallTask {
    if(config.binaries.postInstallScript != nil){
        NSString *output;
        int status = tty([NSString stringWithFormat:@"bash '%@'", config.binaries.postInstallScript], &output);
        switch (status) {
            case 0:
                return output;
            case 1:
                @throw [NSException exceptionWithName:@"KextInstallException" reason:output userInfo:nil];
                return output;
            case 2:
                /// @todo Revert the kext installation
                @throw [NSException exceptionWithName:@"KextInstallException" reason:output userInfo:nil];
                return output;
        }
    }
    return nil;
}

- (BOOL) doAction {
#ifdef DEBUG
    _fprintf(stderr, @"== Installing %@ ==", kextName);
#endif
    // 1. Find and check
    [KextAction status:@"Checking..."];
    if(config.matchesAllCriteria == KCCNoneMatched) {
        [KextAction message:@"The kext couldn't be installed because it is unsupported for your platform." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 1.1 Check for internet connection
    if(!hasInternetConnection()) {
        [KextAction message:@"The kext couldn't be installed because no internet connection is detected." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 1.2 Download requirements
    @try{
        if(![self downloadRequirments]) {
            [KextAction message:@"The kext couldn't be installed because required files could not be downloaded." withStatusCode:EXIT_FAILURE];
            return NO;
        }
    } @catch (NSException *e){
        [KextAction message:@"The kext couldn't be installed because required files could not be downloaded." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 2. Remove conflicts
    [KextAction status:@"Removing conflict(s)..."];
    if(![self removeConflicts]) {
        [KextAction message:@"The kext couldn't be installed because all or some conflicts could not be removed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 3. Install required kexts
    [KextAction status:@"Installing requirement(s)..."];
    if(![self installRequirements]) {
        [KextAction message:@"The kext couldn't be installed because all or some requirments couldn't be installed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 4. Run preinstall tasks
    [KextAction status:@"Running pre-install task(s)..."];
    @try{
        [self runPreInstallTask];
    } @catch (NSException *e) {
        [KextAction message:e.reason withStatusCode:EXIT_FAILURE];
    }
    // 5. Install the kext
    [KextAction status:@"Installing the kext..."];
    if(![self installKext]) {
        [KextAction message:@"Sorry, the kext couldn't be installed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 6. Run post install task
    [KextAction status:@"Running post-install task(s)..."];
    @try {
        NSString *output = [self runPostInstallTask];
        [KextAction message:@"The installation was successful!" withStatusCode:EXIT_SUCCESS];
    } @catch (NSException *e) {
        [KextAction message:e.reason withStatusCode:EXIT_FAILURE];
    }
    return YES;
}

+ (BOOL) unzip: (NSString *) zipFile to: (NSString *) targetFolder {
    int status = tty([NSString stringWithFormat:@"unzip '%@' -d '%@'", zipFile, targetFolder], nil);
    if(status == EXIT_SUCCESS) return YES;
    return NO;
}
+ (BOOL) create: (NSString *) dir {
    NSFileManager *fm = NSFileManager.defaultManager;
    if(![fm fileExistsAtPath:dir]) {
        if(![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil]){
            @throw [NSException exceptionWithName:@"Failed creating directory" reason:[NSString stringWithFormat:@"Failed to create the directory %@", dir] userInfo:nil];
            return NO;
        }
    }
    return YES;
}
+ (BOOL) copy: (NSString *) file to: (NSString *) targetPath {
    if(tty([NSString stringWithFormat:@"cp -R '%@' '%@'", file, targetPath], nil) == EXIT_SUCCESS) return YES;
    return NO;
}
@end

#pragma KextUpdate
@implementation KextUpdate
- (BOOL) installKext {
    NSArray<NSString *> *kextLocations = [kextFinder findLocations:kextName];
    if(![self removeKext:kextName]){ return NO; }
    BinaryHandler *current = config.binaries.recommended;
    BOOL update_everywhere = preference.kexts.anywhere;
    if(current.location != nil){
        NSString *kextPath =[NSString stringWithFormat:@"%@/%@", targetFolder, current.location];
        for(NSString *kextLocation in kextLocations){
            if(!update_everywhere && !([kextLocation hasPrefix:kSLE] || [kextLocation hasPrefix:kLE]))
                continue;
            [KextInstall copy:kextPath to:kextLocation];
            tty([NSString stringWithFormat:@"/usr/sbin/chown -R 0:0 %@", kextLocation], nil);
        }
        return YES;
    }
    return NO;
}
- (BOOL) doAction {
#ifdef DEBUG
    _fprintf(stderr, @"== Updating %@ ==", kextName);
#endif
    // 1. Find and check
    [KextAction status:@"Checking..."];
    if(config.matchesAllCriteria == KCCNoneMatched) {
        [KextAction message:@"The kext couldn't be installed because it is unsupported for your platform." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 1.1 Check for internet connection
    if(!hasInternetConnection()) {
        [KextAction message:@"The kext couldn't be installed because no internet connection is detected." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 1.2 Download requirements
    @try{
        if(![self downloadRequirments]) {
            [KextAction message:@"The kext couldn't be installed because required files could not be downloaded." withStatusCode:EXIT_FAILURE];
            return NO;
        }
    } @catch (NSException *e){
        [KextAction message:@"The kext couldn't be installed because required files could not be downloaded." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 2. Remove conflicts
    [KextAction status:@"Removing conflict(s)..."];
    if(![self removeConflicts]) {
        [KextAction message:@"The kext couldn't be installed because all or some conflicts could not be removed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 3. Install required kexts
    [KextAction status:@"Installing requirement(s)..."];
    if(![self installRequirements]) {
        [KextAction message:@"The kext couldn't be installed because all or some requirments couldn't be installed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 4. Run preinstall tasks
    [KextAction status:@"Running pre-install task(s)..."];
    @try{
        [self runPreInstallTask];
    } @catch (NSException *e) {
        [KextAction message:e.reason withStatusCode:EXIT_FAILURE];
    }
    // 5. Update the kext
    [KextAction status:@"Updating the kext..."];
    if(![self installKext]) {
        [KextAction message:@"Sorry, the kext couldn't be installed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 6. Run post install task
    [KextAction status:@"Running post-install task(s)..."];
    @try {
        NSString *output = [self runPostInstallTask];
        [KextAction message:@"The update was successful!" withStatusCode:EXIT_SUCCESS];
    } @catch (NSException *e) {
        [KextAction message:e.reason withStatusCode:EXIT_FAILURE];
    }
    return YES;
}
@end

#pragma KextRemove
@implementation KextRemove
- (BOOL) doAction {
#ifdef DEBUG
    _fprintf(stderr, @"== Removing %@ ==", kextName);
#endif
    [KextAction status:@"Removing the kext..."];
    if(![self removeKext:kextName]){
        [KextAction message:@"Sorry, the kext couldn't be removed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    [KextAction message:@"The kext was successfully removed." withStatusCode:EXIT_SUCCESS];
    return YES;
}
@end
