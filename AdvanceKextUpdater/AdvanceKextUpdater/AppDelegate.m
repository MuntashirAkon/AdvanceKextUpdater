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
#import "Task.h"
#import "utils.h"
#import "AKUDiskManager.h"
#import "Windows/PreferencesWindowController.h"
#import "Windows/AboutWindowController.h"
#import "Windows/KextViewerWindowController.h"
#import "Windows/Spinner.h"
#import "../Shared/ZSSUserDefaults/ZSSUserDefaults.h"
#import "../Shared/PreferencesHandler.h"
#import "KextFinder.h"
#import "HelperController.h"

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

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {}

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
        _urlKextName = [path lastPathComponent];
        if(_urlKextName != nil){
            if([_urlKextName hasPrefix:@".kext"]){
                _urlKextName = [_urlKextName stringByDeletingPathExtension];
            }
            path = [path stringByDeletingLastPathComponent];
            // Extract verb
            _urlVerb = [path lastPathComponent];
            [self handleURL];
        }
#if DEBUG
        NSLog(@"Decoded URL: %@ - %@", _urlVerb, _urlKextName);
#endif
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Load default preferences
    [ZSSUserDefaults.standardUserDefaults registerDefaults:PreferencesHandler.appDefaults];
    // Check for kext update
    _spinner = [Spinner.alloc initWithTitle:@"Updating database..."];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            // Check if Xcode components are installed
            // There are complication with `xcode-select --install`
            // I may use it instead in future version
            // FIXME: Only works from 10.9? Use git universal binary?
            if(tty([NSString stringWithFormat:@"%@ help", [NSBundle.mainBundle pathForResource:@"git" ofType:nil]], nil) != EXIT_SUCCESS){
                @throw [NSException exceptionWithName:@"No Xcode Command Line Tools!" reason:@"Xcode command line tools are required! Unlike the  Xcode itself the command line tools don't take much space." userInfo:nil];
            }
            // Init Preferences: mount clover if needed
            CloverPreference *cp = [[PreferencesHandler sharedPreferences] clover];
            if(cp.support){
                AKUDiskManager *clover = [AKUDiskManager new];
                [clover setDisk:cp.partition];
                if(![clover isMounted]) [clover mountVolume];
                if([clover getMountPoint] == nil){
                    @throw [NSException exceptionWithName:@"Cannot mount Clover parition" reason:@"You have enabled support for Clover parition, but for some reason this partition cannot be mounted. Please, try starting the app again or report me." userInfo:nil];
                }
                [cp prefixDirectories];
            }
            // Init kextFinder
            [KextFinder sharedKextFinder];
#ifndef DEBUG // Don't disturb me on DEBUG builds
            if(hasInternetConnection()){
                [KextHandler checkForDBUpdate];
                [pciDevice checkForDBUpdate];
            }
#else
        _printf(@"INITIALIZED\n");
#endif
            // Init kextHandler
            [KextHandler createFilesIfNotExist];
            self->kextHandler = [KextHandler sharedKextHandler];
            // Main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                // Init tables
                [self updateTables];
                // Handle URL
                if(!isNull(self->_urlKextName)){[self handleURL];}
            });
        } @catch(NSException *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                NSRunCriticalAlertPanel(e.name, @"%@", nil, nil, nil, e.reason);
                [self applicationWillTerminate:aNotification]; // Terminate
            });
        }
    });
    // Handle kext:// url scheme
    NSAppleEventManager *appleEventManager = NSAppleEventManager.sharedAppleEventManager;
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return true;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {}

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

-(IBAction)reportAnError:(id)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/MuntashirAkon/AdvanceKextUpdater/issues/new"]];
    });
}

-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:NO];
}

-(IBAction)fetchAllKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:YES];
}

-(IBAction)checkForUpdates:(id)sender {
    [[_spinner setTitle:@"Checking for updates..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Find kexts that need updating
        NSArray<NSString *> *kextNeedsUpdate = [self->kextHandler listKextsWithUpdate];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
#ifdef DEBUG
            _printf(@"To be updated %@\n", kextNeedsUpdate);
#endif
            if(kextNeedsUpdate.count > 0){
                NSInteger res = NSRunAlertPanel(@"Update available!", @"The following kext(s) will be updated:\n%@", @"Proceed", @"Cancel Update", nil, [kextNeedsUpdate componentsJoinedByString:@", "]);
                if(res == NSAlertDefaultReturn){
                    // TODO: Display progress as well?
                    [[self->_spinner setTitle:@"Checking for updates..."] reload];
                    [self->_spinner.window makeKeyAndOrderFront:self];
                    [NSApp activateIgnoringOtherApps:YES];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        @try {
                            HelperController.sharedHelper.async = YES;
                            [HelperController.sharedHelper autoUpdate];
                            while([HelperController.sharedHelper isTaskRunning]) { sleep(1); }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_spinner close];
                            });
                        } @catch (NSException *e) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_spinner close];
                                NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
                            });
                        }
                    });
                }
            } else {
                NSRunAlertPanel(@"No update found!", @"No new update is available.", @"OK", nil, nil);
            }
        });
    });
}

-(IBAction)repairPermissions:(id)sender {
    [[_spinner setTitle:@"Repairing permissions..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            HelperController.sharedHelper.async = YES;
            [HelperController.sharedHelper repairPermissions];
            while([HelperController.sharedHelper isTaskRunning]) { sleep(1); }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
            });
        } @catch (NSException *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
            });
        }
    });
}

-(IBAction)rebuildCache:(id)sender {
    [[_spinner setTitle:@"Rebuilding kernel cache..."] reload];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            HelperController.sharedHelper.async = YES;
            [HelperController.sharedHelper rebuildCache];
            while([HelperController.sharedHelper isTaskRunning]) { sleep(1); }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
            });
        } @catch (NSException *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
            });
        }
    });
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
        // Remove previous window
        if(_kextViewer != nil){
            [self.window removeChildWindow:_kextViewer.window];
            [_kextViewer close];
            _kextViewer = nil;
        }
        // Open a new window
        _kextViewer = [KextViewerWindowController.alloc initWithKextConfig:[kextHandler kextConfig:kext]];
        [self.window addChildWindow:_kextViewer.window ordered:NSWindowAbove];
    } @catch (NSException *e) {}
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

-(void) handleURL {
    if([self->allTheKexts indexOfObject:self->_urlKextName] != NSNotFound){
        // The kext IS in the database
        // Perform necessary actions
        [self fetchKextInfo:self->_urlKextName];
        // Run tasks based on verbs
        // as it is the default behavior
        if([self->_urlVerb isEqual:@"guide"]) {
            [self->_kextViewer fetchGuide:self];
        } else if ([self->_urlVerb isEqual:@"install"]) {
            // Install or update the kext
            if([self->_kextViewer isInstallable]){
                sleep(1);
                [self->_kextViewer installKext:self];
            } else if([self->_kextViewer isUpdatable]){
                sleep(1);
                [self->_kextViewer updateKext:self];
            }
        } else if ([self->_urlVerb isEqual:@"remove"]) {
            // Remove the kext
            if([self->_kextViewer isRemovable]){
                sleep(1);
                [self->_kextViewer removeKext:self];
            }
        }
    } else {
        NSRunCriticalAlertPanel(@"Kext not found!", @"The kext (%@) you are trying to open is not found!", nil, nil, nil, self->_urlKextName);
    }
}
@end
