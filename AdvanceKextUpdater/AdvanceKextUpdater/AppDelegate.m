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
#import <MMMarkdown/MMMarkdown.h>
#import "Task.h"
#import "ConfigMacOSVersionControl.h"
#import "ConfigKextVersionControl.h"
#import "hasInternetConnection.m"
#import "ConfigAuthor.h"

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
    [fm createDirectoryAtPath:[KextHandler kextCachePath] withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:[KextHandler guideCachePath] withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:[KextHandler kextTmpPath] withIntermediateDirectories:YES attributes:nil error:nil];
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
            if(hasInternetConnection())
                [KextHandler checkForDBUpdate];
        } @catch(NSException *e) {}
        if(![fm fileExistsAtPath:[KextHandler kextDBPath]]) {
            NSRunCriticalAlertPanel(@"Updating Kext database failed!", @"Failed to update kext database, please check your internet connection and try again.", nil, nil, nil);
            [self applicationWillTerminate:aNotification]; // Terminate
        }
        // Initialize table
        self.overview = [self listInstalledKext];
        self.allKexts = [self listAllKext:YES];
        // Main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self loadingSpinner] stopAnimation:self];
            [[self loadingPanel] close];
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
    installedKexts = [[[KextHandler alloc] init] listInstalledKext];
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
    allTheKexts = [[KextHandler alloc] init].listKext;
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

-(void)fetchKextInfo: (NSTableView *)sender whichDB: (BOOL) allKextsDB {
    @try {
        // Do nothing in case user supplies an invalid row
        if([sender clickedRow] < 0) return;
        // Remove all the child-windows
        [[self guideViewer] close];
        [[self kextViewer] close];
        [[self kextViewer] removeChildWindow:[self guideViewer]];
        [[self window] removeChildWindow:[self kextViewer]];
        // Load kext config
        NSString *kext = allKextsDB ? [allTheKexts objectAtIndex:[sender clickedRow]] : [installedKexts objectAtIndex:[sender clickedRow]];
        KextConfig *kextConfig = [[KextConfig alloc] initWithKextName:kext];
        // If unable to load any kext
        if(kextConfig == nil) {
            NSRunCriticalAlertPanel(@"Missing config.json!", @"A config.json file determines the Kext behaviors and other configurations, which is somehow missing. You can create a new issue on GitHub if you are interested.", @"OK", nil, nil);
            return;
        };
        // Set guide TODO: Use markdown
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
        // Set properties
        homepage = kextConfig.homepage;
        self.kextProperties = @{
            // General properties
            @"kextName": kextConfig.kextName,
            @"description": kextConfig.shortDescription,
            @"license": [kextConfig.license componentsJoinedByString:@", "],
            @"authors": [authors componentsJoinedByString:@", "],
            @"since": [NSString stringWithFormat:@"macOS %@", kextConfig.sinceMacOSVersion],
            @"required": requiredKexts,
            @"conflict": conflictedKexts,
            @"replacedBy": replacedByKexts,
            // Button behaviors
            @"guide_btn": @{
                @"enabled": [kextConfig.guide isEqual:@""] ? @0 : @1
            },
            // Messages
            @"removeConflict": deleteConflict > 0 ? @"Conflicted kext(s) will be removed!" : @"",
            @"criteria_btn": @{ // TODO
                // Possible texts and colors:
                // ✔︎ Matches all criterias     [NSColor greenColor]
                // ✘ Didn't match any criteria  [NSColor redColor]
                // ✘ Didn't match some criteria [NSColor orangeColor]
                @"text": @"✔︎ Matches all criterias",
                @"color": [NSColor greenColor]
            },
            @"homepage_btn": @{
                @"hidden": [self isNull:kextConfig.homepage] ? @1 : @0
            }
        };
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
    // Parse Markdown
    NSError  *error;
    NSString *guideMD = guideHTML;
    guideHTML = [MMMarkdown HTMLStringWithMarkdown:guideMD extensions:MMMarkdownExtensionsGitHubFlavored error:&error];
    if(error != nil){
        guideHTML = @"<p>Incomplete Markdown systax!</p>";
    }
    NSString *cssFile = [NSBundle.mainBundle pathForResource:@"github-markdown" ofType:@"css"];
    return @{
         @"guide": [NSString stringWithFormat:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><style>%@</style><style> .markdown-body{box-sizing:border-box;min-width:200px;max-width:980px;margin:0 auto;padding:45px;} @media (max-width: 767px) {.markdown-body{padding:15px;}} </style><article class=\"markdown-body\">%@</article>", [NSString stringWithContentsOfFile:cssFile encoding:NSUTF8StringEncoding error:nil], guideHTML],
         @"url": url
    };
}

- (BOOL) isNull: (id) sel {
    if(sel == [NSNull null]) return true;
    else if(sel == nil) return true;
    else if([sel isEqual:@""]) return true;
    else if([sel isEqual:@0]) return true;
    return false;
}

- (void)closeAllExceptLoadingPanel {
    [[self kextViewer] close];
    [[self guideViewer] close];
}
@end
