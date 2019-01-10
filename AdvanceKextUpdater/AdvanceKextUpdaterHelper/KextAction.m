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
@synthesize kextName;
/// @param kextName Full kext name ie. with extension
- (instancetype) initWithKext: (NSString *) kextName {
    self->kextName = kextName;
    return self;
}
- (BOOL) doAction {
    // Implement this on every child classes
    return NO;
}

/// Find the location of the kext (if installed)
///
/// Only searches at kSLE and kLE
+ (NSString * _Nullable) find: (NSString *) kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    NSString *location = NSString.string;
    int status = tty([NSString stringWithFormat:@"kextfind | grep '%@$'", kextName], &location);
    if(status == EXIT_SUCCESS) return location;
    return nil;
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
+ (BOOL) removeKext: (NSString *) kextName {
    NSString *kextLocation = [KextAction find:kextName];
    if(kextLocation != nil) {
        [KextAction unload: kextLocation]; // Don't care about the return value
        if(tty([NSString stringWithFormat:@"rm -Rf '%@'", kextLocation], nil) == EXIT_SUCCESS) {
            return YES;
        }
    }
    return NO;
}
+ (NSString * _Nullable) findInstalledVersion: (NSString *) kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    NSString *kextLocation = [self find:kextName];
    if(kextLocation == nil){
        @throw [NSException exceptionWithName:@"KextNotFoundException" reason:@"The requested kext not found. So, can't get a version for a kext that's not installed!" userInfo:nil];
    }
    NSString *plist = [NSString stringWithFormat:@"%@/Contents/Info.plist", kextLocation];
    NSString *version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleShortVersionString"];
    if(version == nil){
        version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleVersion"];
    }
    return version;
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
@synthesize config;
- (instancetype) initWithKext: (NSString *) kextName {
    if([super initWithKext:kextName]){
        self->config = [KextConfig.alloc initWithKextName:kextName];
        return self;
    }
    return nil;
}
- (BOOL) removeConflicts {
    NSArray<ConfigConflictKexts *> *kexts = config.conflict;
    for(ConfigConflictKexts *kext in kexts) {
        // If version is matched, remove it
        @try{
            NSString *version = [KextAction findInstalledVersion:kext.kextName];
            NSComparisonResult result = kext.uptoLatest ? NSOrderedDescending : NSOrderedSame;
            if([kext.version isEqual:@"*"] || [version.shortenedVersionNumberString compare:kext.version options:NSNumericSearch] == result){
                if(![KextAction removeKext:kext.kextName]) return NO;
            }
        } @catch (NSException *e) { continue; } // Not installed
    }
    return YES;
}
- (BOOL) installRequirements {
    NSArray<ConfigRequiredKexts *> *kexts = config.requirments;
    for(ConfigRequiredKexts *kext in kexts) {
        @try{
            NSString *version = [KextAction findInstalledVersion:kext.kextName];
#ifdef DEBUG
            _printf(@"%@ (%@): ", kext.kextName, version);
#endif
            NSComparisonResult result = kext.uptoLatest ? NSOrderedDescending : NSOrderedSame;
            if(![kext.version isEqual:@"*"] && [version.shortenedVersionNumberString compare:kext.version options:NSNumericSearch] != result){
#ifdef DEBUG
                _printf(@"Need updating.\n");
#endif
                if(![[KextUpdate.alloc initWithKext:kext.kextName] doAction]) {// Update kext
                    return NO;
                }
            }
#ifdef DEBUG
            else {
                _printf(@"No need to update.\n");
            }
#endif
        } @catch (NSException *e){
            if(![[KextInstall.alloc initWithKext:kext.kextName] doAction]) {// Install kext
                return NO;
            }
#ifdef DEBUG
            _printf(@"%@: Need installing (%@)\n", kext.kextName, e.reason);
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
    NSString *kextPath = [KextHandler.kextTmpPath stringByAppendingPathComponent:config.kextName];
    [KextInstall create:kextPath];
    NSString *zipFile = [[kextPath stringByAppendingPathComponent:@"Kext"] stringByAppendingPathExtension:@"zip"];
    NSString *targetFolder = [kextPath stringByAppendingPathComponent:@"Kext"];
    if([NSFileManager.defaultManager fileExistsAtPath:targetFolder]){
        [NSFileManager.defaultManager removeItemAtPath:targetFolder error:nil];
    }
    if(current.location != nil){
        // Download zip
        if([URLTask get:[NSURL URLWithString:current.url] toFile:zipFile supress:YES]){
            // Extract and save it to somewhere else
            if([KextInstall unzip:zipFile to:targetFolder]){
                // Copy them to kSLE or kLE
                if([KextInstall copy:[NSString stringWithFormat:@"%@/%@", targetFolder, current.location] to:config.target.target]){
                    NSString *kextLocation = [KextAction find:config.kextName];
                    [KextAction load:kextLocation];
                    return YES;
                }
            }
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
        [KextAction message:output withStatusCode:EXIT_SUCCESS];
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
- (BOOL) doAction {
    // 1. Find and check
    [KextAction status:@"Checking..."];
    if(super.config.matchesAllCriteria == KCCNoneMatched) {
        [KextAction message:@"The kext couldn't be installed because it is unsupported for your platform." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 1.1 Check for internet connection
    if(!hasInternetConnection()) {
        [KextAction message:@"The kext couldn't be installed because no internet connection is detected." withStatusCode:EXIT_FAILURE];
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
    if(![KextAction removeKext:super.kextName]){
        [KextAction message:@"Sorry, the old kext couldn't be removed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    if(![self installKext]) {
        [KextAction message:@"Sorry, the kext couldn't be installed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    // 6. Run post install task
    [KextAction status:@"Running post-install task(s)..."];
    @try {
        NSString *output = [self runPostInstallTask];
        [KextAction message:output withStatusCode:EXIT_SUCCESS];
    } @catch (NSException *e) {
        [KextAction message:e.reason withStatusCode:EXIT_FAILURE];
    }
    return YES;
}
@end

#pragma KextRemove
@implementation KextRemove
- (BOOL) doAction {
    [KextAction status:@"Removing the kext..."];
    if(![KextAction removeKext:super.kextName]){
        [KextAction message:@"Sorry, the kext couldn't be removed." withStatusCode:EXIT_FAILURE];
        return NO;
    }
    [KextAction message:@"The kext was successfully removed." withStatusCode:EXIT_SUCCESS];
    return YES;
}
@end
