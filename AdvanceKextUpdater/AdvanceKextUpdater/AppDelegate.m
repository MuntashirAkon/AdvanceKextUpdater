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
#import "MarkdownToHTML.h"
#import "Task.h"
#import "ConfigMacOSVersionControl.h"
#import "ConfigKextVersionControl.h"
#import "utils.h"
#import "ConfigAuthor.h"
#import "PCI.h"
#import "KIHelperAgrumentController.h"
#import "Windows/PreferencesWindowController.h"
#import "Windows/AboutWindowController.h"

@interface AppDelegate ()
// Outlets
@property IBOutlet NSWindow *window;
@property IBOutlet NSPanel *kextViewer;
@property IBOutlet NSPanel *guideViewer;
@property IBOutlet WebView *guideView;
@property IBOutlet NSPanel *loadingPanel;
@property IBOutlet NSPanel *taskViewer;
@property IBOutlet WebView *taskInfoView;
@property IBOutlet NSProgressIndicator *loadingSpinner;
@end

@implementation AppDelegate {
    PreferencesWindowController *_preferences;
    AboutWindowController *_aboutwindowController;
}

@synthesize overview;
@synthesize allKexts;
@synthesize kextProperties;

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
                [self fetchGuide:nil];
            } else if ([verb isEqual:@"install"]) {
                // Install or update the kext
                if([[self.kextProperties objectForKey:@"install_btn"] objectForKey:@"enabled"]){
                    sleep(1);
                    [self installKext:nil];
                } else if([[self.kextProperties objectForKey:@"update_btn"] objectForKey:@"enabled"]){
                    sleep(1);
                    [self updateKext:nil];
                }
            } else if ([verb isEqual:@"remove"]) {
                // Remove the kext
                if([[self.kextProperties objectForKey:@"remove_btn"] objectForKey:@"enabled"]){
                    sleep(1);
                    [self removeKext:nil];
                }
            }
        } else {
            NSRunCriticalAlertPanel(@"Kext not found!", @"The kext (%@) you are trying to open is not found!", nil, nil, nil, kextName);
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Load default preferences
    [NSUserDefaults.standardUserDefaults registerDefaults:[AppDelegate appDefaults]];
    // Set window levels
    [[self guideViewer]  setLevel:NSNormalWindowLevel];
    [[self kextViewer]   setLevel:NSNormalWindowLevel];
    [[self loadingPanel] setLevel:NSFloatingWindowLevel];
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
    self.loadingTexts = @{
        @"titleText": @"",
        @"subtitleText": @"",
        @"singleText": @"Updating database..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
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
            [self.loadingSpinner stopAnimation:self];
            [self.loadingPanel close];
            if(![fm fileExistsAtPath:KextHandler.kextDBPath]) {
                NSRunCriticalAlertPanel(@"Updating Kext database failed!", @"Failed to update kext database, please check your internet connection and try again.", nil, nil, nil);
                [self applicationWillTerminate:aNotification]; // Terminate
            } else {
                // Init tables again
                [self updateTables];
            }
        });
    });
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

/// @todo
/// - Permforms tasks on the background with a spinner on the main thread
/// - Download and install the binary
-(IBAction)checkForAppUpdates:(id)sender{
    // Get the tag name
    id json = [URLTask getJSON:[NSURL URLWithString:@"https://api.github.com/repos/MuntashirAkon/AdvanceKextUpdater/releases"]];
    if(json != nil) {
        json = [json objectAtIndex:0];
        if(json != nil) {
            NSString *version = [json objectForKey:@"tag_name"];
//            NSString *changelog = [json objectForKey:@"body"];
            NSString *binary  = [[[json objectForKey:@"assets"] objectAtIndex:0] objectForKey:@"browser_download_url"];
            NSString *currentVersion = [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            if([currentVersion.shortenedVersionNumberString compare:version] == NSOrderedAscending) {
                if(NSRunAlertPanel(@"Update available!", @"Current version is %@, and you are running %@.", @"Update", @"Cancel", nil, currentVersion, version) == 0){
                    /// @todo Download the binary
                    [URLTask get:[NSURL URLWithString:binary] toFile:[KextHandler.tmpPath stringByAppendingString:@"/AdvanceKextUpdater.zip"]];
                    
                }
            } else {
                NSRunAlertPanel(@"No new update available!", @"You're running the latest version.", @"OK", nil, nil);
            }
        }
    }
}

#pragma AppDelegate - FetchInstalledKextInfo
-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:NO];
}

#pragma AppDelegate - FetchAllKextInfo
-(IBAction)fetchAllKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:YES];
}

#pragma AppDelegate - FetchGuide
-(IBAction)fetchGuide:(NSButton *)sender {
    if(guide != nil || ![guide isEqual:@""]){
        [[self guideViewer] close];
        [[self kextViewer] removeChildWindow:[self guideViewer]];
        self.loadingTexts = @{
            @"titleText": @"",
            @"subtitleText": @"",
            @"singleText": @"Loading guide..."
        };
        [[self loadingSpinner] startAnimation:self];
        [[self loadingPanel] makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *guideInfo;
            @try {
                guideInfo = [self fetchGuideBackground];
            } @catch (NSException *e) {
                // Do nothing right now.
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *url = [guideInfo objectForKey:@"url"] == [NSNull null] ? nil : [guideInfo objectForKey:@"url"];
                [[self loadingSpinner] stopAnimation:self];
                [[self loadingPanel] close];
                [[[self guideView] mainFrame] loadHTMLString:[[guideInfo objectForKey:@"guide"] stringByReplacingOccurrencesOfString:@"<a " withString:@"<a target='_blank' "] baseURL:url];
                [[self kextViewer] addChildWindow:[self guideViewer] ordered:NSWindowAbove];
                [NSApp activateIgnoringOtherApps:YES];
            });
        });
    }
}

-(IBAction)checkForUpdates:(id)sender {
    self.loadingTexts = @{
        @"titleText": @"",
        @"subtitleText": @"",
        @"singleText": @"Checking for updates..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //[self repairPermissionsBackground];
        /// @todo
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
        });
    });
}

#pragma AppDelegate - RepairPermissions
-(IBAction)repairPermissions:(id)sender {
    self.loadingTexts = @{
      @"titleText": @"",
      @"subtitleText": @"",
      @"singleText": @"Repairing permissions..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self repairPermissionsBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
        });
    });
}

#pragma AppDelegate - RebuildCache
-(IBAction)rebuildCache:(id)sender {
    self.loadingTexts = @{
        @"titleText": @"",
        @"subtitleText": @"",
        @"singleText": @"Rebuilding kernel cache..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self rebuildCacheBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
        });
    });
}

-(IBAction)gotoHomepage:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homepage]];
}

-(IBAction)fetchSuggestions:(NSButton *)sender {
    /// @todo
}

-(IBAction)installKext:(NSButton *)sender {
    taskType = KextInstall;
    [NSApp beginSheet:_taskViewer modalForWindow:_kextViewer modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext(s) will be installed:\n"];
    [taskString appendFormat:@"- %@\n", [self.kextProperties objectForKey:@"kextName"]];
    for(NSDictionary *kext in [self.kextProperties objectForKey:@"required"]){
        [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kextName"]];
    }
    NSDictionary *conflicts = [self.kextProperties objectForKey:@"conflict"];
    if(conflicts.count > 0){
        [taskString appendString:@"\n#### The following kext(s) will be removed:\n"];
        /// @todo Check if installed
        for(NSDictionary *kext in conflicts){
            [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kextName"]];
        }
    }
    [[self taskInfoView].mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)updateKext:(NSButton *)sender {
    taskType = KextUpdate;
    [NSApp beginSheet:_taskViewer modalForWindow:_kextViewer modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext(s) will be updated or installed:\n"];
    [taskString appendFormat:@"- %@\n", [self.kextProperties objectForKey:@"kextName"]];
    for(NSDictionary *kext in [self.kextProperties objectForKey:@"required"]){
        [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kextName"]];
    }
    NSDictionary *conflicts = [self.kextProperties objectForKey:@"conflict"];
    if(conflicts.count > 0){
        [taskString appendString:@"\n#### The following kext(s) will be removed:\n"];
        /// @todo Check if installed
        for(NSDictionary *kext in conflicts){
            [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kextName"]];
        }
    }
    [[self taskInfoView].mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)removeKext:(NSButton *)sender {
    taskType = KextRemove;
    [NSApp beginSheet:_taskViewer modalForWindow:_kextViewer modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext(s) will be removed:\n"];
    /// @todo Check if installed
    [taskString appendFormat:@"- %@\n", [self.kextProperties objectForKey:@"kextName"]];
    [[self taskInfoView].mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)runTask:(NSButton *)sender {
    // Do not proceed if another task running
    if([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]){
        NSRunCriticalAlertPanel(@"Invalid request!", @"A process is already running, wait until it is finished.", @"OK", nil, nil);
        [self closeTaskViwer:sender];
        return;
    }
    [self closeTaskViwer:sender];
    // Install kext
    self.loadingTexts = @{
        @"titleText": [NSString stringWithFormat:@"Installing %@...", [self.kextProperties objectForKey:@"kextName"]],
        @"subtitleText": @"Checking...",
        @"singleText": @""
    };
    [self.loadingSpinner startAnimation:self];
    [self.loadingPanel makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runTaskBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingSpinner stopAnimation:self];
            [self.loadingPanel close];
            // Run complete, now get result
            NSString *messageStr = [NSString stringWithContentsOfFile:KextHandler.messageFile encoding:NSUTF8StringEncoding error:nil];
            NSArray *messageArr = [messageStr componentsSeparatedByString:@"\n"];
            int status = [[messageArr objectAtIndex:0] intValue];
            NSString *message = [messageArr objectAtIndex:1];
            // If successful, add the kexts to the installedKexts list
            if(status == EXIT_SUCCESS){
                [self->installedKexts addObject:[self.kextProperties objectForKey:@"kextName"]];
                for(NSDictionary *kext in [self.kextProperties objectForKey:@"required"]){
                    [self->installedKexts addObject:[kext objectForKey:@"kextName"]];
                }
                /// @todo updating UI isn't working for the main window
                [self listInstalledKext];
                [self fetchKextInfo:[self.kextProperties objectForKey:@"kextName"]];
                NSRunAlertPanel(@"Success!", @"%@", @"OK", nil, nil, message);
            } else {
                NSRunCriticalAlertPanel(@"Failed!", @"%@", @"OK", nil, nil, message);
            }
        });
    });
}

-(IBAction)closeTaskViwer:(NSButton *)sender {
    [NSApp endSheet:_taskViewer];
    [_taskViewer close];
    [[self taskInfoView].mainFrame loadHTMLString:@"" baseURL:nil];
}

// Helper functions
- (NSDictionary *) listInstalledKext {
    installedKexts = [NSMutableArray arrayWithArray:self->kextHandler.listInstalledKext];
    int sn = 0;
    NSMutableArray *kexts = [NSMutableArray array];
    for(NSString *kext in installedKexts) {
        [kexts addObject:@{
           @"number": @(++sn),
           @"kext"  : kext
        }];
    }
    return @{@"IKTable": kexts};
}

- (NSDictionary *) listAllKext: (BOOL) deviceOnly { /// @todo
    allTheKexts = self->kextHandler.listKext;
    remoteKexts = self->kextHandler.listRemoteKext;
    int sn = 0;
    NSMutableArray *kexts = [NSMutableArray array];
    for(NSString *kext in allTheKexts) {
        [kexts addObject:@{
            @"number": @(++sn),
            @"kext"  : kext
        }];
    }
    return @{@"AKTable": kexts};
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
    // Get the kext name
    NSString *kextName = allKextsDB ? [allTheKexts objectAtIndex:[sender clickedRow]] : [installedKexts objectAtIndex:[sender clickedRow]];
    [self fetchKextInfo:kextName];
}

/// @todo do it in the background as find() takes a lot of time
-(void)fetchKextInfo: (NSString *)kext {
    @try {
        // Remove all the child-windows
        [self closeTaskViwer:nil];
        [[self guideViewer] close];
        [[self kextViewer] close];
        [[self kextViewer] removeChildWindow:[self guideViewer]];
        [[self window] removeChildWindow:[self kextViewer]];
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
        // Check if criterias are matched
        KextConfigCriteria kcc_status = [kextConfig matchesAllCriteria];
        NSDictionary *criteria_msg;
        switch (kcc_status){
            case KCCAllMatched:
                criteria_msg = @{
                    @"text": @"✔︎ Matches all the criteria",
                    @"color": COLOR_GREEN
                };
                break;
            case KCCSomeMatched:
                criteria_msg = @{
                    @"text": @"✘ Didn't match some criteria",
                    @"color": COLOR_ORANGE
                };
                break;
            case KCCNoneMatched:
                criteria_msg = @{
                    @"text": @"✘ Didn't match any criterion",
                    @"color": COLOR_RED
                };
                break;
            default:
                criteria_msg = @{
                    @"text": @"✘ Kext cannot be installed",
                    @"color": COLOR_RED
                };
        }
        // Set guide
        guide = kextConfig.guide;
        // List required kexts
        NSMutableArray<NSDictionary *> *requiredKexts = [NSMutableArray array];
        for(ConfigRequiredKexts *kext in kextConfig.requirments){
            [requiredKexts addObject:@{
                @"kextName": kext.kextName,
                @"kextVersion": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : kext.version
            }];
        }
        // List conflicted kexts
        BOOL deleteConflict = NO;
        NSMutableArray<NSDictionary *> *conflictedKexts = [NSMutableArray array];
        for(ConfigConflictKexts *kext in kextConfig.conflict){
            deleteConflict = !deleteConflict && [kext.action isEqual: @"delete"] ? YES : NO;
            [conflictedKexts addObject:@{
                @"kextName": kext.kextName,
                @"kextVersion": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : kext.version
            }];
        }
        // List replaced kexts
        NSMutableArray<NSDictionary *> *replacedByKexts = [NSMutableArray array];
        for(ConfigReplacedByKexts *kext in kextConfig.replacedBy){
            [replacedByKexts addObject:@{
                @"kextName": kext.kextName,
                @"kextVersion": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : kext.version
            }];
        }
        // Authors
        NSMutableArray<NSString *> *authors = [NSMutableArray array];
        for(ConfigAuthor *author in kextConfig.authors){
            [authors addObject:author.name];
        }
        // Whether the kext is installable
        // FIXME: Use an enum to merge all these options
        BOOL installable = kcc_status < KCCSomeMatchedAllRestricted ? YES : NO;
        BOOL installed = [self isInstalled:kextConfig.kextName];
        BOOL updateAvailable = NO;
        if(installed){
            @try{
                NSString *version = [self findInstalledVersion:kextConfig.kextName];
                updateAvailable = [kextConfig.versions newerThanVersion:version];
            } @catch (NSException *e) {
                [self listInstalledKext];
                [self fetchKextInfo:[self.kextProperties objectForKey:@"kextName"]];
            }
        }
        // Set properties
        homepage = kextConfig.homepage;
        self.kextProperties = @{
            // General properties
            @"kextName": kextConfig.kextName,
            @"description": kextConfig.shortDescription,
            @"license": [kextConfig.license componentsJoinedByString:@", "],
            @"authors": [authors componentsJoinedByString:@", "],
            @"since": [NSString stringWithFormat:@"macOS %@", kextConfig.macOSVersion.lowestVersion],
            @"required": requiredKexts,
            @"conflict": conflictedKexts,
            @"replacedBy": replacedByKexts,
            // Button behaviors
            @"guide_btn": @{
                @"enabled": [kextConfig.guide isEqual:@""] ? @0 : @1
            },
            @"homepage_btn": @{
                @"hidden": isNull(kextConfig.homepage) ? @1 : @0
            },
            @"install_btn": @{
                @"enabled": (installed || !installable) ? @0 : @1
            },
            @"remove_btn": @{
                @"enabled": installed ? @1 : @0
            },
            @"update_btn": @{
                @"enabled": updateAvailable ? @1 : @0
            },
            // Messages
            @"removeConflict": deleteConflict > 0 ? @"Conflicted kext(s) will be removed!" : @"",
            @"criteria_btn": criteria_msg
        };
//        [NSApp runModalForWindow:[self kextViewer]];
        [[self window] addChildWindow:[self kextViewer] ordered:NSWindowAbove];
    } @catch (NSError *e) {
        // Do nothing
        return;
    }
}

- (NSDictionary *) fetchGuideBackground {
    id guideHTML;
    id url = [NSNull null];
    // Check for @see <URL>
    if([guide hasPrefix:@"@see "]){
        // Guide is located in the URL
        url = [NSURL URLWithString:[guide substringFromIndex:5]];
        // Cache URL
        NSString *cacheFile = [[[KextHandler guideCachePath] stringByAppendingPathComponent:[self.kextProperties objectForKey:@"kextName"]] stringByAppendingPathExtension:@"md"];
        // Load HTML
        guideHTML = [NSNull null];
        @try {
            // load from cache, if available
            if([NSFileManager.defaultManager fileExistsAtPath:cacheFile])
                guideHTML = [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:nil];
            // download HTML
            if(hasInternetConnection()){
                [URLTask get:url toFile:cacheFile supress:YES];
                if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]){
                    guideHTML = [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:nil];
                } else {
                    guideHTML = @"The URL not found!";
                }
            } else if(guideHTML == [NSNull null]) {
                guideHTML = @"No network connection detected";
            }
        } @catch (NSError *e) {
            [NSFileManager.defaultManager removeItemAtPath:cacheFile error:nil];
        } @catch (NSException *e) {
            [NSFileManager.defaultManager removeItemAtPath:cacheFile error:nil];
        } @finally {
            if(guideHTML == [NSNull null]){
                guideHTML = @"Guide not found. Please make an issue on GitHub.";
            }
        }
    } else {
        // Guide is provided as a string
        guideHTML = guide;
    }
    return @{
         @"guide": [MarkdownToHTML.alloc initWithMarkdown:guideHTML].render,
         @"url": url
    };
}

// Separate file?
- (void) runTaskBackground {
    NSString *kextName = [self.kextProperties objectForKey:@"kextName"];
    switch (taskType) {
        case KextInstall:
            [KIHelperAgrumentController install:kextName];
            break;
        case KextUpdate:
            [KIHelperAgrumentController update:kextName];
            break;
        case KextRemove:
            [KIHelperAgrumentController remove:kextName];
            break;
        default:
            return;
    }
    // Create the lockfile
    [NSFileManager.defaultManager createFileAtPath:KextHandler.lockFile contents:[@"Checking..." dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    //
    // Create, Copy and Load the launch agent
    //
    @try{
        if (![NSFileManager.defaultManager fileExistsAtPath:KextHandler.launchDaemonPlistFile]) {
            NSString *launchAgent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
            "<plist version=\"1.0\">\n"
            "    <dict>\n"
            "        <key>Label</key>\n"
            "        <string>%@</string>"
            "        <key>Program</key>\n"
            "        <string>%@</string>"
            "        <key>RunAtLoad</key>\n"
            "        <true/>"
            "        <key>WorkingDirectory</key>\n"
            "        <string>%@</string>"
            "        <key>StandardInPath</key>\n"
            "        <string>%@</string>"
            "        <key>StandardOutPath</key>\n"
            "        <string>%@</string>"
            "        <key>StandardErrorPath</key>\n"
            "        <string>%@</string>"
            "    </dict>\n"
            "</plist>\n", launchDaemonName, [NSBundle.mainBundle pathForResource:@"AdvanceKextUpdaterHelper" ofType:nil], KextHandler.tmpPath, KextHandler.stdinPath, KextHandler.stdoutPath, KextHandler.stderrPath];
            NSString *agentPlist = [[KextHandler.tmpPath stringByAppendingPathComponent:launchDaemonName] stringByAppendingPathExtension:@"plist"];
            // Save Info.plist @ tmpPath
            [NSFileManager.defaultManager createFileAtPath:agentPlist contents:[launchAgent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
            // Copy & load
            NSString *launchDaemonsRootDir = @"/Library/LaunchDaemons/";
            [AScript adminExec:[NSString stringWithFormat:@"cp %@ %@ && launchctl load %@", agentPlist, launchDaemonsRootDir, KextHandler.launchDaemonPlistFile]];
        } else {
            // Launch daemon already exist, simply load it
            [AScript adminExec:[NSString stringWithFormat:@"launchctl load %@", KextHandler.launchDaemonPlistFile]];
        }
    } @catch (NSError *e){
        // FIXME: delete STDIN file?
#ifdef DEBUG
        NSLog(@"User cancelled");
#endif
        return;
    }
    // Check for the background tasks until they are complete
    while([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]) {
        [self performSelectorOnMainThread:@selector(updateTaskInfo) withObject:self waitUntilDone:YES];
        sleep(1);
    }
}

- (void) updateTaskInfo {
    @try {
        NSString *status = [NSString stringWithContentsOfFile:KextHandler.lockFile encoding:NSUTF8StringEncoding error:nil];
        self.loadingTexts = @{
            @"titleText": [NSString stringWithFormat:@"Installing %@...", [self.kextProperties objectForKey:@"kextName"]],
            @"subtitleText": status,
            @"singleText": @""
        };
    } @catch (NSError *e) {}
}

- (void) updateTables {
    // Init KextHandler
    self->kextHandler = [KextHandler.alloc init];
    // Initialize table
    self.overview = [self listInstalledKext];
    self.allKexts = [self listAllKext:YES];
}

// Check if a kext is installed (with extension)
- (BOOL) isInstalled: (NSString *) kextName {
    if([installedKexts indexOfObject:kextName] != NSNotFound) {
        return YES;
    }
    return NO;
}

- (NSString *) findInstalledVersion: (NSString *) kextName {
    NSString *kext = find(kextName);
    if(kextName == nil) {
        @throw [NSException exceptionWithName:@"KextNotFoundException" reason:@"The requested kext not found. So, can't get a version for a kext that's not installed!" userInfo:nil];
    }
    NSString *plist = [NSString stringWithFormat:@"%@/Contents/Info.plist", kext];
    NSString *version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleShortVersionString"];
    if(version == nil){
        version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleVersion"];
    }
    return version;
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
            if (volume_kind != NULL) { // Since Clover only supports ntfs and msdos
                if (CFEqual(volume_kind, CFSTR("hfs")) || CFEqual(volume_kind, CFSTR("msdos"))) {
                    [result addObject:@{
                        @"BSDName": BSDName,
                        @"Label": (__bridge NSString *)volume_label
                    }];
                }
                //if(volume_kind != NULL){ CFRelease(volume_kind); }
                //if(volume_label != NULL){ CFRelease(volume_label); }
            }
//            CFURLRef fspath = CFDictionaryGetValue(diskInfo,kDADiskDescriptionVolumePathKey);
//
//            char buf[MAXPATHLEN];
//            if (CFURLGetFileSystemRepresentation(fspath, false, (UInt8 *)buf, sizeof(buf))) {
//                printf("Disk %s mounted at %s\n",
//                       DADiskGetBSDName(disk),
//                       buf);
//
//                /* Print the complete dictionary for debugging. */
//                CFShow(diskInfo);
//            } else {
//                /* Something is *really* wrong. */
//            }
        }
        if (diskInfo != NULL) { CFRelease(diskInfo); }
        if (disk != NULL) { CFRelease(disk); }
        if (session != NULL) { CFRelease(session); }
    }
    NSLog(@"%@", result);
    return result.copy;
}

+(NSDictionary *)appDefaults{
    return @{
        @"Kext": @{
            @"Check":@0, // Do not check
            @"Update":@NO,
            @"Replace":@NO,
            @"Anywhere":@YES, // Otherwise just LE or SLE
            @"Backup":@YES,
            @"Exclude":@[]
        },
        @"Clover": @{
            @"Support":@NO,
            @"Partition":@"",
            @"Directories":@[
                @"Other", @"10.6", @"10.7", @"10.8", @"10.9", @"10.10",
                @"10.11", @"10.12", @"10.13", @"10.14"
            ]
        }
    };
}
@end
