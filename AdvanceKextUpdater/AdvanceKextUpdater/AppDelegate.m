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
#import "MarkdownToHTML.h"
#import "Task.h"
#import "ConfigMacOSVersionControl.h"
#import "ConfigKextVersionControl.h"
#import "hasInternetConnection.m"
#import "ConfigAuthor.h"
#import "PCI.h"

@interface AppDelegate ()
// Outlets
@property IBOutlet NSWindow *window;
@property IBOutlet NSPanel *kextViewer;
@property IBOutlet NSPanel *guideViewer;
@property IBOutlet NSPanel *loadingPanel;
@property IBOutlet WebView *guideView;
@property IBOutlet NSProgressIndicator *loadingSpinner;
@end

@implementation AppDelegate

@synthesize overview;
@synthesize allKexts;
@synthesize kextProperties;

// Handle kext:// url scheme
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Check if Xcode components are installed
    // There are complication with `xcode-select --install`
    // I may use it instead in future version
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSBundle.mainBundle pathForResource:@"git" ofType:nil];
    task.arguments = @[@"help"];
    [task launch];
    [task waitUntilExit];
    if(task.terminationStatus != 0){
        NSRunCriticalAlertPanel(@"No Xcode Command Line Tools!", @"Xcode command line tools are required! Unlike the  Xcode itself the command line tools don't take much space.", nil, nil, nil);
        [self applicationWillTerminate:aNotification]; // Terminate
    }
    // Init KextHandler
    self->kextHandler = KextHandler.alloc.init;
    // Initialize table
    self.overview = [self listInstalledKext];
    self.allKexts = [self listAllKext:YES];

    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *path = [[[event paramDescriptorForKeyword:keyDirectObject] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // Currently only supports kext://<verb>/<kext-name>
    // Supported verbs: kext (optional), guide, install, remove
    if([path hasPrefix:@"kext://"]){
        path = [path substringFromIndex:7];
        // Extract kext name
        NSString *kextName = [path lastPathComponent];
        path = [path stringByDeletingLastPathComponent];
        // Extract verb
        NSString *verb = [path lastPathComponent];
        NSLog(@"%@: %@", verb, kextName);
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
                // TODO: install/update the kext (with a prompt)
            } else if ([verb isEqual:@"remove"]) {
                // TODO: remove a kext (with a prompt)
            }
        } else {
            NSRunCriticalAlertPanel(@"Kext not found!", @"The kext (%@) you are trying to open is not found!", nil, nil, nil, kextName);
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
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
    // Check for kext update
    self.loadingTexts = @{
        @"titleText": @"",
        @"subtitleText": @"",
        @"singleText": @"Updating database..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
#ifndef DEBUG // Don't disturb me on DEBUG builds
            if(hasInternetConnection()){
                [KextHandler checkForDBUpdate];
                [pciDevice checkForDBUpdate];
            }
#endif
        } @catch(NSException *e) {}
        // Main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
            if(![fm fileExistsAtPath:[KextHandler kextDBPath]]) {
                NSRunCriticalAlertPanel(@"Updating Kext database failed!", @"Failed to update kext database, please check your internet connection and try again.", nil, nil, nil);
                [self applicationWillTerminate:aNotification]; // Terminate
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

-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:NO];
}

-(IBAction)fetchAllKextInfo:(NSTableView *)sender {
    [self fetchKextInfo:sender whichDB:YES];
}

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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
                [[[self guideView] mainFrame] loadHTMLString:[guideInfo objectForKey:@"guide"] baseURL:url];
                [[self kextViewer] addChildWindow:[self guideViewer] ordered:NSWindowAbove];
                [NSApp activateIgnoringOtherApps:YES];
            });
        });
    }
}

-(IBAction)repairPermissions:(NSButton *)sender {
    self.loadingTexts = @{
      @"titleText": @"",
      @"subtitleText": @"",
      @"singleText": @"Repairing permissions..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self repairPermissionsBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
        });
    });
}

-(IBAction)rebuildCache:(NSButton *)sender {
    self.loadingTexts = @{
        @"titleText": @"",
        @"subtitleText": @"",
        @"singleText": @"Rebuilding kernel cache..."
    };
    [[self loadingSpinner] startAnimation:self];
    [[self loadingPanel] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
    
}

// Helper functions
- (NSDictionary *) listInstalledKext {
    installedKexts = self->kextHandler.listInstalledKext;
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

- (NSDictionary *) listAllKext: (BOOL) deviceOnly { // TODO
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
-(void)fetchKextInfo: (NSString *)kext {
    @try {
        // Remove all the child-windows
        [[self guideViewer] close];
        [[self kextViewer] close];
        [[self kextViewer] removeChildWindow:[self guideViewer]];
        [[self window] removeChildWindow:[self kextViewer]];
        KextConfig *kextConfig;
        if([remoteKexts objectForKey:kext] != nil) {
            kextConfig = [KextConfig.alloc initWithKextName:kext URL:[remoteKexts objectForKey:kext]];
        } else {
            kextConfig = [KextConfig.alloc initWithKextName:kext];
        }
        // If unable to load any kext
        if(kextConfig == nil) {
            NSRunCriticalAlertPanel(@"Missing config.json!", @"A config.json file determines the Kext behaviors and other configurations, which is somehow missing. You can create a new issue on GitHub if you are interested.", @"OK", nil, nil);
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
            // TODO: Show based on version
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
            NSString *version = [self findInstalledVersion:kextConfig.kextName];
            updateAvailable = [kextConfig.versions newerThanVersion:version];
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

// Check if a kext is installed (with extension)
- (BOOL) isInstalled: (NSString *) kextName {
    if([installedKexts indexOfObject:kextName] != NSNotFound) {
        return YES;
    }
    return NO;
}

- (NSString *) findInstalledVersion: (NSString *) kextName {
    NSString *plist = [NSString stringWithFormat:@"%@/%@/Contents/Info.plist", kSLE, kextName];
    // First check at SLE
    if(![NSFileManager.defaultManager fileExistsAtPath:plist]) {
        if ([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11){
            // Search at LE
            plist = [NSString stringWithFormat:@"%@/%@/Contents/Info.plist", kLE, kextName];
            if(![NSFileManager.defaultManager fileExistsAtPath:plist])
                @throw [NSException exceptionWithName:@"KextNotFoundException" reason:@"The requested kext not found. So, can't get a version for a kext that's not installed!" userInfo:nil];
        } else {
            @throw [NSException exceptionWithName:@"KextNotFoundException" reason:@"The requested kext not found. So, can't get a version for a kext that's not installed!" userInfo:nil];
        }
    }
    NSString *version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleShortVersionString"];
    if(version == nil){
        version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleVersion"];
    }
    return version;
}
@end
