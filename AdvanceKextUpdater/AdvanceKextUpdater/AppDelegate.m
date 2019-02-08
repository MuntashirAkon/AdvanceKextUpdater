//
//  AppDelegate.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import "AppDelegate.h"
#import "KextConfig.h"
#import "KextHandler.h"
#import <Webkit/Webkit.h> // for WebView
#import <DiskArbitration/DiskArbitration.h> // Disk
#import "Task.h"
#import "utils.h"
#import "AKUDiskManager.h"
#import "Windows/PreferencesWindowController.h"
#import "Windows/AboutWindowController.h"
#import "Windows/KextViewerWindowController.h"
#import "Windows/Spinner.h"
#import "../Shared/ZSSUserDefaults/ZSSUserDefaults.h"
#import "../Shared/PreferencesHandler.h"

@interface AppDelegate ()
@property IBOutlet NSWindow *window;
// Windows
@property PreferencesWindowController *preferences;
@property AboutWindowController *aboutwindowController;
@property KextViewerWindowController *kextViewer;
@property Spinner *spinner;
// Tables
@property IBOutlet NSTableView *overviewTable;
@property IBOutlet NSTableView *allKextsTable;
// Table data
@property IBOutlet NSArrayController *overview;
@property IBOutlet NSArrayController *allKexts;
@end

@implementation AppDelegate

// Handle kext:// url scheme
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Check if Xcode components are installed
    // There are complication with `xcode-select --install`
    // I may use it instead in future version
    // FIXME: Only works from 10.9? Use git universal binary?
    NSTask *task = [[NSTask alloc] init];
    NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
    [task setStandardOutput:nullFileHandle];
    [task setStandardError:nullFileHandle];
    task.launchPath = [NSBundle.mainBundle pathForResource:@"git" ofType:nil];
    task.arguments = @[@"help"];
    [task launch];
    [task waitUntilExit];
    if(task.terminationStatus != 0){
        NSRunCriticalAlertPanel(@"No Xcode Command Line Tools!", @"Xcode command line tools are required! Unlike the  Xcode itself the command line tools don't take much space.", nil, nil, nil);
        [self applicationWillTerminate:aNotification]; // Terminate
    }
    // Init KextHandler
    self->kextHandler = [KextHandler sharedKextHandler];
    // Init tables
    [self updateTables];

    NSAppleEventManager *appleEventManager = NSAppleEventManager.sharedAppleEventManager;
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *path = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // Currently only supports kext://<verb>/<kext-name>
    // Supported verbs: kext (optional), guide, install, remove
    NSString *prefix = @"kext://";
    if([path hasPrefix:prefix]){
        // Just open the app if arguments are empty
        if(path.length == prefix.length) return;
        path = [path substringFromIndex:prefix.length];
        // Extract kext name
        NSString *kextName = [path lastPathComponent];
        path = [path stringByDeletingLastPathComponent];
        // Extract verb
        NSString *verb = [path lastPathComponent];
        // NSLog(@"%@: %@", verb, kextName);
        // Just open the app if kextName is nil
        if(kextName == nil) return;
        // Verfiy if it's in the database
        if(([allTheKexts indexOfObject:[kextName stringByAppendingPathExtension:@"kext"]] != NSNotFound) || [allTheKexts indexOfObject:kextName] != NSNotFound){
            // The kext IS in the database
            // Perform necessary actions
            [self fetchKextInfo:kextName];
            // Run tasks based on verbs
            // NOTE: we do not require this condition: verb == nil || [verb isEqual:@"kext"]
            // as it is the default behavior
            if([verb isEqual:@"guide"]) {
                [_kextViewer fetchGuide:self];
            } else if ([verb isEqual:@"install"]) {
                // Install or update the kext
//                if([[self.kextProperties objectForKey:@"install_btn"] objectForKey:@"enabled"]){
//                    sleep(1);
//                    [self installKext:nil];
//                } else if([[self.kextProperties objectForKey:@"update_btn"] objectForKey:@"enabled"]){
//                    sleep(1);
//                    [self updateKext:nil];
//                }
            } else if ([verb isEqual:@"remove"]) {
                // Remove the kext
//                if([[self.kextProperties objectForKey:@"remove_btn"] objectForKey:@"enabled"]){
//                    sleep(1);
//                    [self removeKext:nil];
//                }
            }
        } else {
            NSRunCriticalAlertPanel(@"Kext not found!", @"The kext (%@) you are trying to open is not found!", nil, nil, nil, kextName);
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Load default preferences
    [ZSSUserDefaults.standardUserDefaults registerDefaults:PreferencesHandler.appDefaults];
    // Set window levels
    [NSApp activateIgnoringOtherApps:YES];
    // Create paths in application support directory if not exists
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *appPath = [KextHandler appPath];
    if(![fm fileExistsAtPath:appPath]){
        NSError *err;
        if(![fm createDirectoryAtPath:appPath withIntermediateDirectories:YES attributes:nil error:&err]){
            NSRunCriticalAlertPanel(@"Application Support isn't accessible!", @"Creating an important directory at Application Support directory failed!\nDetails: %@", nil, nil, nil, err);
            [self applicationWillTerminate:aNotification]; // Terminate
        }
    }
    [fm createDirectoryAtPath:KextHandler.kextCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.guideCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.kextTmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:KextHandler.kextBackupPath withIntermediateDirectories:YES attributes:nil error:nil];

    // Check for kext update
    _spinner = [Spinner.alloc initWithTitle:@"Updating database..."];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#ifndef DEBUG // Don't disturb me on DEBUG builds
        @try {
            if(hasInternetConnection()){
                [KextHandler checkForDBUpdate];
                [pciDevice checkForDBUpdate];
            }
        } @catch(NSException *e) {}
#else
        _printf(@"INITIALIZED\n");
#endif
        // Main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
            if(![fm fileExistsAtPath:KextHandler.kextDBPath]) {
                NSRunCriticalAlertPanel(@"Updating Kext database failed!", @"Failed to update kext database, please check your internet connection and try again.", nil, nil, nil);
                [self applicationWillTerminate:aNotification]; // Terminate
            } else {
                // Init tables again
                [self updateTables];
            }
        });
    });
    //[self getListOfCloverInstallationLocation];
//    AKUDiskManager *clover = [AKUDiskManager new];
//    [clover setDisk:@"disk0s1"];
//    [clover mountVolume];
//    _printf([clover getMountPoint]);
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return true;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma AppDelegate - Preferences
-(IBAction)preferences:(id)sender{
    if(_preferences == nil){
        _preferences = [PreferencesWindowController new];
    }
    [_preferences.window makeKeyAndOrderFront:self];
}

-(IBAction)about:(id)sender{
    if (_aboutwindowController == nil) {
        _aboutwindowController = [AboutWindowController new];
    }
    [_aboutwindowController.window makeKeyAndOrderFront:self];
}

-(IBAction)openKextStatViewer:(id)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSWorkspace.sharedWorkspace openFile:[[NSBundle.mainBundle builtInPlugInsPath] stringByAppendingPathComponent:@"KextStatViewer.app"]];
    });
}

-(IBAction)checkForAppUpdates:(id)sender{
    _spinner = [Spinner.alloc initWithTitle:@"Checking for update..."];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        @try{
            if(!hasInternetConnection()){ @throw [NSException exceptionWithName:@"No internet connection" reason:@"No active network connection is detected." userInfo:nil]; }
            // Fetch JSON
            id json = [URLTask getJSON:[NSURL URLWithString:@"https://api.github.com/repos/MuntashirAkon/AdvanceKextUpdater/releases"]];
            if(json == nil){ @throw [NSException exceptionWithName:@"Error while checking for update" reason:@"The server returned things that shouldn't be returned!" userInfo:nil]; }
            // The first item is the latest
            json = [json objectAtIndex:0];
            if(json == nil){ @throw [NSException exceptionWithName:@"Error while checking for update" reason:@"The server returned things that shouldn't be returned!" userInfo:nil]; }
            // Get version, changelog and binary
            NSString *version = [json objectForKey:@"tag_name"];
            //            NSString *changelog = [json objectForKey:@"body"];
            NSString *binary  = [[[json objectForKey:@"assets"] objectAtIndex:0] objectForKey:@"browser_download_url"];
            NSString *currentVersion = [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            // Main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                if([currentVersion.shortenedVersionNumberString compare:version] == NSOrderedAscending) {
                    if(NSRunAlertPanel(@"Update available!", @"Current version is %@, and you are running %@.", @"Update", @"Cancel", nil, version, currentVersion) == NSAlertDefaultReturn){
                        self->_spinner = [Spinner.alloc initWithTitle:@"Updating..."];
                        [self->_spinner.window makeKeyAndOrderFront:self];
                        [NSApp activateIgnoringOtherApps:YES];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                            @try{
                                NSString *downloadPath = [[KextHandler.tmpPath stringByAppendingPathComponent:@"AdvanceKextUpdater"] stringByAppendingPathExtension:@"zip"];
                                NSString *appPath = [[KextHandler.tmpPath stringByAppendingPathComponent:@"AdvanceKextUpdater"] stringByAppendingPathExtension:@"app"];
                                //exit(0);
                                tty([NSString stringWithFormat:@"rm -Rf '%@'", appPath], nil);
                                if(![URLTask get:[NSURL URLWithString:binary] toFile:downloadPath supress:YES]){
                                    @throw [NSException exceptionWithName:@"Error updating!" reason:@"Error downloading update. Please try again later or check your internet connection." userInfo:nil];
                                }
                                if(!unzip(downloadPath, KextHandler.tmpPath)){
                                    @throw [NSException exceptionWithName:@"Error updating!" reason:@"Error extracting the update file. Please try again later." userInfo:nil];
                                }
                                tty([NSString stringWithFormat:@"rm -Rf '%@'", downloadPath], nil);
                                if(tty([NSString stringWithFormat:@"rm -Rf '%@' && mv '%@' '%@'", NSBundle.mainBundle.bundlePath, appPath, NSBundle.mainBundle.bundlePath], nil) != EXIT_SUCCESS){
                                    @throw [NSException exceptionWithName:@"Error updating!" reason:@"Error moving the update file. Please try again later." userInfo:nil];
                                }
                                // Main thread
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self->_spinner close];
                                    if(NSRunCriticalAlertPanel(@"Update complete!", @"", @"Relaunch", nil, nil) == NSAlertDefaultReturn){
                                        system([NSString stringWithFormat:@"sleep 2 && open -n '%@'", NSBundle.mainBundle.bundlePath].UTF8String);
                                        exit(0);
                                    }
                                });
                            } @catch (NSException *e){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self->_spinner close];
                                    NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
                                });
                            }
                        });
                    }
                } else {
                    NSRunAlertPanel(@"No new update available!", @"You're running the latest version.", @"OK", nil, nil);
                }
            });
        } @catch (NSException *e){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
            });
        }
    });
}

#pragma AppDelegate - FetchInstalledKextInfo
-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:NO];
}

#pragma AppDelegate - FetchAllKextInfo
-(IBAction)fetchAllKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:YES];
}

-(IBAction)checkForUpdates:(id)sender {
    [[_spinner setTitle:@"Checking for updates..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //[self repairPermissionsBackground];
        /// @todo
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
        });
    });
}

#pragma AppDelegate - RepairPermissions
-(IBAction)repairPermissions:(id)sender {
    [[_spinner setTitle:@"Repairing permissions..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self repairPermissionsBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
        });
    });
}

#pragma AppDelegate - RebuildCache
-(IBAction)rebuildCache:(id)sender {
    [[_spinner setTitle:@"Rebuilding kernel cache..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self rebuildCacheBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
        });
    });
}

-(IBAction)fetchSuggestions:(NSButton *)sender {
    /// @todo
}

// Helper functions
- (NSArray *) listInstalledKext {
    installedKexts = [NSMutableArray arrayWithArray:self->kextHandler.listInstalledKext];
    int sn = 0;
    NSMutableArray *kexts = [NSMutableArray array];
    for(NSString *kext in installedKexts) {
        [kexts addObject:@{
           @"no": @(++sn),
           @"kext": kext
        }];
    }
    return kexts;
}

- (NSArray *) listAllKext: (BOOL) deviceOnly { /// @todo
    allTheKexts = self->kextHandler.listKext;
    remoteKexts = self->kextHandler.listRemoteKext;
    int sn = 0;
    NSMutableArray *kexts = [NSMutableArray array];
    for(NSString *kext in allTheKexts) {
        [kexts addObject:@{
            @"no": @(++sn),
            @"kext": kext
        }];
    }
    return kexts;
}

// Background tasks

- (void) repairPermissionsBackground {
    @try {
        NSString *command = [NSString stringWithFormat:@"/bin/chmod -RN %@;/usr/bin/find %@ -type d -print0 | /usr/bin/xargs -0 /bin/chmod 0755;/usr/bin/find %@ -type f -print0 | /usr/bin/xargs -0 /bin/chmod 0644;/usr/sbin/chown -R 0:0 %@;/usr/bin/xattr -cr %@", kSLE, kSLE, kSLE, kSLE, kSLE];
        if([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11){
            // Also repair permissions for LE if macOS versions is gte 10.11
            command = [NSString stringWithFormat:@"%@;/bin/chmod -RN %@;/usr/bin/find %@ -type d -print0 | /usr/bin/xargs -0 /bin/chmod 0755;/usr/bin/find %@ -type f -print0 | /usr/bin/xargs -0 /bin/chmod 0644;/usr/sbin/chown -R 0:0 %@;/usr/bin/xattr -cr %@", command, kLE, kLE, kLE, kLE, kLE];
        }
        [AScript adminExec:command];
    } @catch (NSError *e) {
        printf("Error: %s\n", [[[e userInfo] objectForKey:@"details"] UTF8String]);
    }
}

- (void) rebuildCacheBackground {
    @try {
        if([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11){ // `kextcache -i /` for 10.11 or later
            [AScript adminExec:@"/usr/sbin/kextcache -i /; "];
        } else { // `touch /S*/L*/Extensions; kextcache -Boot -U /` for 10.10 or earlier
            [AScript adminExec:[NSString stringWithFormat:@"/usr/bin/touch %@;/usr/sbin/kextcache -Boot -U /", kSLE]];
        }
    } @catch (NSError *e) {
        printf("Error: %s\n", [[[e userInfo] objectForKey:@"details"] UTF8String]);
    }
}

// Maybe in a seperate class?
-(void)fetchKextInfo: (NSTableView *)sender whichDB: (BOOL) allKextsDB {
    // Do nothing in case user supplies an invalid row
    if([sender clickedRow] < 0) return;
    // Get the clicked row
    NSTableColumn *columns = [sender tableColumnWithIdentifier:@"kexts"];
    NSTextFieldCell *cell = [columns dataCellForRow:[sender clickedRow]];
    [self fetchKextInfo:cell.stringValue];
}

-(void)fetchKextInfo: (NSString *)kext {
    @try {
        // Load kext config
        KextConfig *kextConfig;
        if([remoteKexts objectForKey:kext] != nil) {
            kextConfig = [KextConfig.alloc initWithKextName:kext URL:[remoteKexts objectForKey:kext]];
        } else {
            kextConfig = [KextConfig.alloc initWithKextName:kext];
        }
        // If unable to load any kext
        if(kextConfig == nil) {
            NSRunCriticalAlertPanel(@"Missing config.json!", @"A config.json file determines the Kext behaviors and other configurations, which is somehow missing. You can create a new issue on GitHub if you are interested.", @"OK", nil, nil);
            // FIXME: Memory leaking of kextConfig
            return;
        };
        // Find the best version for the running macOS version
        NSInteger best_version = kextConfig.versions.findTheBestVersion;
        if(best_version != -1) kextConfig = [kextConfig.versions.availableVersions objectAtIndex:best_version].config;
        // Remove previous window
        if(_kextViewer != nil){
            [self.window removeChildWindow:_kextViewer.window];
            [_kextViewer close];
            _kextViewer = nil;
        }
        // Open a new window
        _kextViewer = [KextViewerWindowController.alloc initWithKextConfig:kextConfig andIsInstalled:[self isInstalled:kextConfig.kextName]];
        [self.window addChildWindow:_kextViewer.window ordered:NSWindowAbove];
    } @catch (NSError *e) {
        // Do nothing
        return;
    }
}

- (void) updateTables {
    // Add objects
    [_overview setContent:nil];
    [_allKexts setContent:nil];
    [_overview addObjects:[self listInstalledKext]];
    [_allKexts addObjects:[self listAllKext:YES]];
    // Reload table
    [_overviewTable reloadData];
    [_overviewTable deselectAll:self];
    [_allKextsTable reloadData];
    [_allKextsTable deselectAll:self];
}

// Check if a kext is installed (with extension)
- (BOOL) isInstalled: (NSString *) kextName {
    if([installedKexts indexOfObject:kextName] != NSNotFound) {
        return YES;
    }
    return NO;
}

-(NSArray *)getListOfCloverInstallationLocation {
    NSArray *BSDNames = NSArray.array;
    tty(@"cd /dev && ls disk*s*", &BSDNames);
    NSMutableArray *result = NSMutableArray.array;
    for(NSString *BSDName in BSDNames) {
        int                 err = 0;
        DADiskRef           disk = NULL;
        DASessionRef        session;
        CFDictionaryRef     diskInfo = NULL;
        session = DASessionCreate(NULL);
        if (session == NULL) { err = EINVAL; }
        if (err == 0) {
            disk = DADiskCreateFromBSDName(NULL, session, BSDName.UTF8String);
            if (session == NULL) { err = EINVAL; }
        }
        if (err == 0) {
            diskInfo = DADiskCopyDescription(disk);
            if (diskInfo == NULL) { err = EINVAL; }
        }
        if (err == 0) {
            CFTypeRef volume_kind  = CFDictionaryGetValue(diskInfo, kDADiskDescriptionVolumeKindKey);
            CFTypeRef volume_label = CFDictionaryGetValue(diskInfo, kDADiskDescriptionVolumeNameKey);
            CFURLRef fspath = CFDictionaryGetValue(diskInfo,kDADiskDescriptionVolumePathKey);
            char buf[MAXPATHLEN];
            CFURLGetFileSystemRepresentation(fspath, false, (UInt8 *)buf, sizeof(buf));
            if (volume_kind != NULL) { // Since Clover only supports ntfs and msdos
                if (CFEqual(volume_kind, CFSTR("hfs")) || CFEqual(volume_kind, CFSTR("msdos"))) {
                    [result addObject:@{
                        @"BSDName": BSDName,
                        @"Label": (__bridge NSString *)volume_label,
                        @"Path": [NSString stringWithUTF8String:buf]
                    }];
                }
            }
        }
        if (diskInfo != NULL) { CFRelease(diskInfo); }
        if (disk != NULL) { CFRelease(disk); }
        if (session != NULL) { CFRelease(session); }
    }
    NSLog(@"%@", result);
    return result.copy;
}

@end
