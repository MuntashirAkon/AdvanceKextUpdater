//
//  KextViewer.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 31/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "KextViewerWindowController.h"
#import <Webkit/Webkit.h>
#import "../KIHelperAgrumentController.h"
#import "../MarkdownToHTML.h"
#import "../Task.h"
#import "../KextFinder.h"
#import "Spinner.h"

@interface KextViewerWindowController ()
// Guide view
@property IBOutlet NSPanel *guidePanel;
@property IBOutlet WebView *guideView;
// Task view
@property IBOutlet NSPanel *taskPanel;
@property IBOutlet WebView *taskInfoView;
// Kext Properties
@property IBOutlet NSTextField *kextName;
@property IBOutlet NSTextField *currentVersion;
@property IBOutlet NSTextField *installedVersion;
@property IBOutlet NSTextView *descriptionView;
@property IBOutlet NSButton *guideBtn;
@property IBOutlet NSButton *websiteBtn;
@property IBOutlet NSTextField *license;
@property IBOutlet NSTextField *authors;
@property IBOutlet NSTextField *since;
@property IBOutlet NSButton *installBtn;
@property IBOutlet NSButton *updateBtn;
@property IBOutlet NSButton *removeBtn;
@property IBOutlet NSTableView *requiredTable;
@property IBOutlet NSTableView *conflictTable;
@property IBOutlet NSTableView *replacedByTable;
@property IBOutlet NSArrayController *required;
@property IBOutlet NSArrayController *conflicts;
@property IBOutlet NSArrayController *replacedBy;
@property IBOutlet NSTextField *conflictWarning;
@property IBOutlet NSTextField *criteriaMsg;
@property BOOL installed;
@property KextConfig *kextConfig;
@property NSMutableArray<NSString *> *authorList;
@property KextInstallerType taskType;
@property Spinner *spinner;
@end

@implementation KextViewerWindowController
@synthesize kextConfig;
-(instancetype)init{ return nil; } // No default constructor

-(instancetype)initWithKextConfig: (KextConfig *) kextConfig {
    self = [super init];
    self.kextConfig = kextConfig;
    _installed = [KextFinder.sharedKextFinder isInstalled:kextConfig.kextName];
    _authorList = NSMutableArray.array;
    for(ConfigAuthor *author in kextConfig.authors){
        [_authorList addObject:author.name];
    }
    return self;
}

-(NSNibName)windowNibName {
    return @"KextViewer";
}

-(BOOL)shouldCascadeWindows {
    return YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Make Webviews transparent
    _guideView.drawsBackground = NO;
    _taskInfoView.drawsBackground = NO;
    // Set kext properties
    [_kextName setStringValue:kextConfig.kextName];
    [_currentVersion setStringValue:kextConfig.version];
    [_descriptionView setString:kextConfig.shortDescription];
    [_license setStringValue:[kextConfig.license componentsJoinedByString:@", "]];
    [_authors setStringValue:[_authorList componentsJoinedByString:@", "]];
    [_since setStringValue:[NSString stringWithFormat:@"macOS %@", kextConfig.macOSVersion.lowestVersion]];
    _guideBtn.enabled = [kextConfig.guide isEqual:@""] ? NO : YES;
    _websiteBtn.hidden = isNull(kextConfig.homepage) ? YES : NO;
    for(ConfigRequiredKexts *kext in kextConfig.requirments){
        [_required addObject:@{
           @"kext": kext.kextName,
           @"version": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : ([kext.version isEqualToString:@"*"] ? @"All" : kext.version )
        }];
    }
    for(ConfigConflictKexts *kext in kextConfig.conflict){
        [_conflicts addObject:@{
            @"kext": kext.kextName,
            @"version": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : ([kext.version isEqualToString:@"*"] ? @"All" : kext.version )
        }];
    }
    for(ConfigReplacedByKexts *kext in kextConfig.replacedBy){
        [_replacedBy addObject:@{
            @"kext": kext.kextName,
            @"version": kext.uptoLatest ? [NSString stringWithFormat:@"%@ & later", kext.version] : ([kext.version isEqualToString:@"*"] ? @"All" : kext.version )
        }];
    }
    [_requiredTable reloadData];
    [_conflictTable reloadData];
    [_replacedByTable reloadData];
    _conflictWarning.hidden = [_conflicts.content count] > 0 ? NO : YES;
    // Check if all the criteria are matched
    KextConfigCriteria kcc_status = [kextConfig matchesAllCriteria];
    switch (kcc_status){
        case KCCAllMatched:
            [_criteriaMsg setStringValue:@"✔︎ Matches all the criteria"];
            _criteriaMsg.textColor = COLOR_GREEN;
            break;
        case KCCSomeMatched:
            [_criteriaMsg setStringValue:@"✘ Didn't match some criteria"];
            _criteriaMsg.textColor = COLOR_ORANGE;
            break;
        case KCCNoneMatched:
            [_criteriaMsg setStringValue:@"✘ Didn't match any criterion"];
            _criteriaMsg.textColor = COLOR_RED;
            break;
        default:
            [_criteriaMsg setStringValue:@"✘ Kext cannot be installed"];
            _criteriaMsg.textColor = COLOR_RED;
    }
    //
    if(_installed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try{
                BOOL installable = kcc_status < KCCSomeMatchedAllRestricted ? YES : NO;
                BOOL updateAvailable = NO;
                NSString *version = [KextFinder.sharedKextFinder findVersion:self->kextConfig.kextName];
                updateAvailable = [self->kextConfig.versions newerThanVersion:version];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_installedVersion setStringValue:version];
                    self->_installBtn.enabled = (self->_installed || !installable) ? NO : YES;
                    self->_updateBtn.enabled = updateAvailable;
                    self->_removeBtn.enabled = self->_installed;
                });
            } @catch (NSException *e) {}
        });
    }else{
        self->_installBtn.enabled = YES;
        [self->_installedVersion setStringValue:@"Not installed"];
    }
}

-(IBAction)gotoHomepage:(NSButton *)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kextConfig.homepage]];
}

-(IBAction)installKext:(id)sender {
    _taskType = KextInstall;
    [NSApp beginSheet:_taskPanel modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext(s) will be installed:\n"];
    [taskString appendFormat:@"- %@\n", kextConfig.name];
    for(NSDictionary *kext in _required.content){
        [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kext"]];
    }
    if([_conflicts.content count] > 0){
        [taskString appendString:@"\n#### The following kext(s) will be removed:\n"];
        /// @todo Check if installed
        for(NSDictionary *kext in _conflicts.content){
            [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kext"]];
        }
    }
    [_taskInfoView.mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)updateKext:(id)sender {
    _taskType = KextUpdate;
    [NSApp beginSheet:_taskPanel modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext(s) will be updated or installed:\n"];
    [taskString appendFormat:@"- %@\n", kextConfig.name];
    for(NSDictionary *kext in _required.content){
        [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kext"]];
    }
    if([_conflicts.content count] > 0){
        [taskString appendString:@"\n#### The following kext(s) will be removed:\n"];
        /// @todo Check if installed
        for(NSDictionary *kext in _conflicts.content){
            [taskString appendFormat:@"- %@\n", [kext objectForKey:@"kext"]];
        }
    }
    [_taskInfoView.mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)removeKext:(id)sender {
    _taskType = KextRemove;
    [NSApp beginSheet:_taskPanel modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    NSMutableString *taskString = [NSMutableString stringWithUTF8String:"#### The following kext will be removed:\n"];
    // TODO: Include kext(s) that are no longer needed?
    [taskString appendFormat:@"- %@\n", kextConfig.name];
    [_taskInfoView.mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:taskString].render baseURL:nil];
}

-(IBAction)closeTaskViwer:(NSButton *)sender {
    [NSApp endSheet:_taskPanel];
    [_taskPanel close];
}

-(IBAction)fetchGuide:(id)sender {
    if(kextConfig.guide != nil || ![kextConfig.guide isEqual:@""]){
        Spinner *spinner = [Spinner.alloc initWithTitle:@"Loading guide..."];
        [spinner.window makeKeyAndOrderFront:self];
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
                [spinner close];
                [self->_guideView.mainFrame loadHTMLString:[[guideInfo objectForKey:@"guide"] stringByReplacingOccurrencesOfString:@"<a " withString:@"<a target='_blank' "] baseURL:url];
                [self.window addChildWindow:self->_guidePanel ordered:NSWindowAbove];
                [NSApp activateIgnoringOtherApps:YES];
            });
        });
    }
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
    _spinner = [Spinner.alloc initWithTitle:[NSString stringWithFormat:@"Installing %@...", kextConfig.kextName] AndSubtitle:@"Checking..."];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runTaskBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_spinner close];
            // Run complete, now get result
            NSString *messageStr = [NSString stringWithContentsOfFile:KextHandler.messageFile encoding:NSUTF8StringEncoding error:nil];
            NSArray *messageArr = [messageStr componentsSeparatedByString:@"\n"];
            int status = [[messageArr objectAtIndex:0] intValue];
            NSString *message = [messageArr objectAtIndex:1];
            // If no message is generated, it was a failed project
            if(messageArr.count < 1){
                status = EXIT_FAILURE;
                message = @"Failed executing the task. Please, try again.";
            }
            // If successful, add the kexts to the installedKexts list
            if(status == EXIT_SUCCESS){
                // TODO [self updateTables];
                // TODO [self fetchKextInfo:[self.kextProperties objectForKey:@"kextName"]];
                NSRunAlertPanel(@"Success!", @"%@", @"OK", nil, nil, message);
            } else {
                NSRunCriticalAlertPanel(@"Failed!", @"%@", @"OK", nil, nil, message);
            }
        });
    });
}

- (void) runTaskBackground {
        NSString *kextName = kextConfig.kextName;
    switch (_taskType) {
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
            NSString *agentPlist = [[KextHandler.appCachePath stringByAppendingPathComponent:launchDaemonName] stringByAppendingPathExtension:@"plist"];
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

-(void)updateTaskInfo {
    @try {
        NSString *status = [NSString stringWithContentsOfFile:KextHandler.lockFile encoding:NSUTF8StringEncoding error:nil];
        [_spinner setTitle:[NSString stringWithFormat:@"Installing %@...", kextConfig.kextName] AndSubtitile:status];
        [_spinner.reload.window makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    } @catch (NSError *e) {}
}

- (NSDictionary *) fetchGuideBackground {
    id guideHTML;
    id url = [NSNull null];
    // Check for @see <URL>
    if([kextConfig.guide hasPrefix:@"@see "]){
        // Guide is located in the URL
        url = [NSURL URLWithString:[kextConfig.guide substringFromIndex:5]];
        // Cache URL
        NSString *cacheFile = [[KextHandler.guideCachePath stringByAppendingPathComponent:kextConfig.kextName] stringByAppendingPathExtension:@"md"];
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
        guideHTML = kextConfig.guide;
    }
    return @{
             @"guide": [MarkdownToHTML.alloc initWithMarkdown:guideHTML].render,
             @"url": url
             };
}
@end
