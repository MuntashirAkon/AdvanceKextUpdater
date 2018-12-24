//
//  KextInstaller.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 12/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextInstaller.h"
#import "KextHandler.h"

// Exit codes
#define PI_ALL_DONE 0
#define PI_INSTALL  1
#define PI_FAILURE  2
#define PI_NO_SCRIPT 3 // Private code

@implementation KextInstaller

// No default init
- (instancetype) init { return nil; }

//- (instancetype) initWithConfig: (KextConfig *) config {
//    bin = config.binaries;
////    adminTask = STPrivilegedTask.alloc.init;
//    currentBin = bin.recommended; // FIXME: Allow user to choose
//    return self;
//}

// FIXME: NSDictionary writeToURL:error: doesn't work!!!
- (BOOL) copyAllTo: (NSString *) tmpDir {
    // Declare directories
    NSString *scripts_dir = [tmpDir stringByAppendingPathComponent:@"scripts"];
    NSString *required_dir = [tmpDir stringByAppendingPathComponent:@"required"];
    NSString *conflicted_dir = [tmpDir stringByAppendingPathComponent:@"conflicted"]; // TODO conflicted kext script removal isn't impemented
    // Create directories
    [self create:scripts_dir];
    [self create:required_dir];
    [self create:conflicted_dir];
    // Create Info.plist
    BinaryHandler *current = self.binaries.recommended; // FIXME let user choose the value
    NSMutableArray<NSString *> *required = NSMutableArray.array;
    NSMutableString *requiredStr = NSMutableString.string;
    if(self.requirments.count > 0){
        [requiredStr appendString:@"        <array>\n"];
        for(ConfigRequiredKexts *req in self.requirments){
            [requiredStr appendString:[NSString stringWithFormat:@"            <string>%@</string>\n", req.kextName]];
            [required addObject:req.kextName];
        }
        [requiredStr appendString:@"        </array>\n"];
    } else {
        [requiredStr appendString:@"        <false/>\n"];
    }
    // FIXME: See if it is installed
    NSMutableArray<NSString *> *conflicted = NSMutableArray.array;
    NSMutableString *conflictedStr = NSMutableString.string;
    if(self.conflict.count > 0){
        [conflictedStr appendString:@"        <array>\n"];
        for(ConfigConflictKexts *con in self.conflict){
            [conflictedStr appendString:[NSString stringWithFormat:@"            <string>%@</string>\n", con.kextName]];
            [conflicted addObject:con.kextName];
        }
        [conflictedStr appendString:@"        </array>\n"];
    } else {
        [conflictedStr appendString:@"        <false/>\n"];
    }
    NSString *preinstallscript = (current.script == nil ? @"        <false/>\n" : [NSString stringWithFormat:@"        <string>%@</string>\n", current.script]);
    NSString *postinstallscript = (self.binaries.postInstallScript == nil ? @"        <false/>\n" : [NSString stringWithFormat:@"        <string>%@</string>\n", self.binaries.postInstallScript]);
//    NSDictionary *info;
    NSString *infoPlist = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        "<plist version=\"1.0\">\n"
        "    <dict>\n"
        "        <key>preinstallscript</key>\n"
        "%@"
        "        <key>postinstallscript</key>\n"
        "%@"
        "        <key>required</key>\n"
        "%@"
        "        <key>conflicted</key>\n"
        "%@"
        "    </dict>\n"
        "</plist>\n", preinstallscript, postinstallscript, requiredStr, conflictedStr];
//    @try {
//        info = @{
//            @"preinstallscript": (current.script == nil ? @NO : current.script),
//            @"postinstallscript": (self.binaries.postInstallScript == nil ? @NO : self.binaries.postInstallScript),
//            @"required": (required.count > 0 ? required.copy : @NO),
//            @"conflicted": (conflicted.count > 0 ? conflicted.copy : @NO)
//        };
//    } @catch (NSException *e){
//#ifdef DEBUG
//        NSLog(@"KextInstaller@Dictionary");
//        NSLog(@"Script: %@", current.script);
//        NSLog(@"PIScript: %@", self.binaries.postInstallScript);
//        NSLog(@"Required: %@", [required copy]);
//        NSLog(@"Conflicts: %@", [conflicted copy]);
//#endif
//    }
    // Save Info.plist @ tmpDir
    NSString *infoPlistFile = [[tmpDir stringByAppendingPathComponent:@"Info"] stringByAppendingPathExtension:@"plist"];
    // Save the plist
    [NSFileManager.defaultManager createFileAtPath:infoPlistFile contents:[infoPlist dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
//    if (@available(macOS 10.13, *)) {
//        NSLog(@"Written: %hhd", [info writeToURL:[NSURL URLWithString:[infoPlistFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] error:nil]);
//    } else {
//        [info writeToFile:infoPlistFile atomically:YES];
//    }
#ifdef DEBUG
    if(![NSFileManager.defaultManager fileExistsAtPath:infoPlistFile]){
        NSLog(@"Couldn't write Info.plist at %@", infoPlistFile);
    }
#endif
    // Copy necessary files to the directory
    // 1. preinstallation script
    NSURL *tmpURL;
    if(current.script != nil){
        if(self.url != nil) tmpURL = [[NSURL URLWithString:self.url] URLByAppendingPathComponent:current.script];
        else tmpURL = [[NSURL URLWithString:self.path] URLByAppendingPathComponent:current.script];
        [self copy:tmpURL to:scripts_dir];
    }
    // 2. postinstallation script
    if(self.binaries.postInstallScript != nil){
        if(self.url != nil) tmpURL = [[NSURL URLWithString:self.url] URLByAppendingPathComponent:self.binaries.postInstallScript];
        else tmpURL = [[NSURL URLWithString:self.path] URLByAppendingPathComponent:self.binaries.postInstallScript];
        [self copy:tmpURL to:scripts_dir];
    }
    // 3. required kexts
    NSDictionary *remoteKexts = [KextHandler.alloc init].listRemoteKext;
    for(NSString *reqKext in required){
        NSString *tmpDir = [required_dir stringByAppendingPathComponent:reqKext];
        if([remoteKexts objectForKey:reqKext] != nil)
            [[KextInstaller.alloc initWithKextName:reqKext URL:[remoteKexts objectForKey:reqKext]] copyAllTo:tmpDir];
        else
            [[KextInstaller.alloc initWithKextName:reqKext] copyAllTo:tmpDir];
    }
    // 4. conflicted kexts (script only)
    // TODO Scripts are allowed in furute
    return NO;
}

- (BOOL) copy: (NSURL *) file to: (NSString *) dir {
    @try {
    return [NSFileManager.defaultManager copyItemAtURL:file toURL:[NSURL URLWithString:dir] error:nil];
    } @catch (NSException *e) {
        NSLog(@"file: %@", file);
        NSLog(@"target: %@", dir);
    }
}

- (BOOL) create: (NSString *) dir {
    NSFileManager *fm = NSFileManager.defaultManager;
    if(![fm fileExistsAtPath:dir]) {
        if(![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil]){
            @throw [NSException exceptionWithName:@"Failed creating directory" reason:[NSString stringWithFormat:@"Failed to create the directory %@", dir] userInfo:nil];
            return NO;
        }
    }
    return YES;
}
//- (int) runPreInstallTask {
//    returnCode = PI_NO_SCRIPT;
//    if(currentBin.script == nil){
//        return PI_NO_SCRIPT;
//    }
//    // TODO: Check for script: Whether it is remote or local
//    //       If remote, download and save it to this->script again
//    // TODO: Execute the script as admin and get output along with the exit code
//    STPrivilegedTask *adminTask = STPrivilegedTask.alloc.init;
//    [adminTask setLaunchPath: currentBin.script]; // FIXME: set full path
//    [adminTask setArguments: @[currentBin.url]];
//    [adminTask setCurrentDirectoryPath: KextHandler.kextTmpPath]; // Fixme (switch between kextCachePath and kextTmpPath
//    OSStatus err = [adminTask launch];
//    if (err != errAuthorizationSuccess) {
//        if (err == errAuthorizationCanceled) {
//            @throw [NSException exceptionWithName:@"User cancelled" reason:@"The execution is cancelled by the user" userInfo:nil];
//        }  else {
//            @throw [NSException exceptionWithName:@"Something went wrong" reason:[NSString stringWithFormat:@"Something went wrong: %d", (int)err] userInfo:nil];
//            // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
//        }
//    }
//
//    [adminTask waitUntilExit];
//
//    // Success!  Now, start monitoring output file handle for data
//    NSFileHandle *readHandle = [adminTask outputFileHandle];
//    NSData *outputData = [readHandle readDataToEndOfFile];
//    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
//
//    switch (adminTask.terminationStatus) {
//        case PI_ALL_DONE:
//            // Every thing's done
//            // Do some checkings
//            // Run post-install
//            returnCode = PI_ALL_DONE;
//            return PI_ALL_DONE;
//        case PI_INSTALL:
//            // Need to install the Kext(s)
//            // Separate the output string by '\n'
//            // TODO
//            kexts = [outputString componentsSeparatedByString:@"\n"];
//            returnCode = PI_INSTALL;
//            return PI_INSTALL;
//        case PI_FAILURE:
//            // Failed to run the whole script
//            returnCode = PI_FAILURE;
//            // Display a friendly message to the user
//            @throw [NSException exceptionWithName:@"Failed execution of pre-install script" reason:outputString userInfo:nil];
//        default:
//            // Through an Exception saying unknown exit code
//            @throw [NSException exceptionWithName:@"Unknown Exit Code" reason:@"The pre-install script has returned an unknown exit code!" userInfo:nil];
//    }
//}
//
//- (NSString *) runPostInstallTask {
//    if(bin.postInstallScript == nil){
//        // No task avialable
//        return nil;
//    }
//    // TODO: Check for script: Whether it is remote or local
//    //       If remote, download and save it to this->postInstallScript again
//    // TODO: Execute the script as admin and get output along with the exit code
//    [adminTask setLaunchPath: bin.postInstallScript]; // FIXME: set full path
//    [adminTask setArguments: @[@(returnCode)]];
//    [adminTask setCurrentDirectoryPath: KextHandler.kextTmpPath]; // Fixme (switch between kextCachePath and kextTmpPath
//    OSStatus err = [adminTask launch];
//    if (err != errAuthorizationSuccess) {
//        if (err == errAuthorizationCanceled) {
//            @throw [NSException exceptionWithName:@"User cancelled" reason:@"The execution is cancelled by the user" userInfo:nil];
//        }  else {
//            @throw [NSException exceptionWithName:@"Something went wrong" reason:[NSString stringWithFormat:@"Something went wrong: %d", (int)err] userInfo:nil];
//            // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
//        }
//    }
//
//    [adminTask waitUntilExit];
//
//    // Success!  Now, start monitoring output file handle for data
//    NSFileHandle *readHandle = [adminTask outputFileHandle];
//    NSData *outputData = [readHandle readDataToEndOfFile];
//    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
//
//    switch (adminTask.terminationStatus) {
//        case PI_ALL_DONE:
//            // Every thing's done
//            return outputString;
//        case PI_INSTALL:
//            // Something's wrong
//            // Display a friendly message to the user
//            @throw [NSException exceptionWithName:@"Failed execution of post-install script" reason:outputString userInfo:nil];
//        case PI_FAILURE:
//            // Something's wrong
//            // Revert installation
//            [self revertInstallation];
//            // Display a friendly message to the user
//            @throw [NSException exceptionWithName:@"Failed execution of pre-install script" reason:outputString userInfo:nil];
//        default:
//            // Through an Exception saying unknown exit code
//            @throw [NSException exceptionWithName:@"Unknown Exit Code" reason:@"The post-install script has returned an unknown exit code!" userInfo:nil];
//    }
//}

@end
