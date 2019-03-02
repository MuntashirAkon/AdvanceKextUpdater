//
//  KextViewer.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 31/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "KextViewerWindowController.h"
#import <Webkit/Webkit.h>
#import "../MarkdownToHTML.h"
#import "../Task.h"
#import "../KextFinder.h"
#import "../AppDelegate.h"
#import "Spinner.h"
#import "../HelperController.h"

@interface KextViewerWindowController ()
// Guide view
@property IBOutlet NSPanel *guidePanel;
@property IBOutlet WebView *guideView;
// Task view
@property IBOutlet NSPanel *taskPanel;
@property IBOutlet WebView *taskInfoView;
// Suggested view
@property IBOutlet NSPanel *suggestedPanel;
@property IBOutlet WebView *suggestedView;
// Kext Properties
@property IBOutlet NSTextField *kextName;
@property IBOutlet NSTextField *currentVersion;
@property IBOutlet NSTextField *installedVersion;
@property IBOutlet NSTextView *descriptionView;
@property IBOutlet NSButton *guideBtn;
@property IBOutlet NSButton *websiteBtn;
@property IBOutlet NSButton *suggestedBtn;
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
    _suggestedView.drawsBackground = NO;
    // Set kext properties
    [_kextName setStringValue:kextConfig.kextName];
    [_currentVersion setStringValue:kextConfig.version];
    [_descriptionView setString:kextConfig.shortDescription];
    [_license setStringValue:[kextConfig.license componentsJoinedByString:@", "]];
    [_authors setStringValue:[_authorList componentsJoinedByString:@", "]];
    [_since setStringValue:[NSString stringWithFormat:@"macOS %@", kextConfig.macOSVersion.lowestVersion]];
    _guideBtn.enabled = [kextConfig.guide isEqual:@""] ? NO : YES;
    _websiteBtn.hidden = isNull(kextConfig.homepage) ? YES : NO;
    _suggestedBtn.hidden = kextConfig.suggestions.count == 0 ? YES : NO;
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
        @try{
            BOOL installable = kcc_status < KCCSomeMatchedAllRestricted ? YES : NO;
            BOOL updateAvailable = NO;
            NSString *version = [KextFinder.sharedKextFinder findVersion:self->kextConfig.kextName];
            updateAvailable = [self->kextConfig.versions newerThanVersion:version];
            [self->_installedVersion setStringValue:version];
            self->_installBtn.enabled = (self->_installed || !installable) ? NO : YES;
            self->_updateBtn.enabled = updateAvailable;
            self->_removeBtn.enabled = self->_installed;
        } @catch (NSException *e) {}
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
                [self->_guidePanel makeKeyWindow];
            });
        });
    }
}

-(IBAction)fetchSuggestion:(id)sender {
    [self.window addChildWindow:_suggestedPanel ordered:NSWindowAbove];
    [_suggestedPanel makeKeyWindow];
    NSMutableString *suggestStr = NSMutableString.string;
    [suggestStr appendString:@"### Suggestions\n\n<dl>"];
    for(ConfigSuggestion *suggestion in kextConfig.suggestions){
        if(suggestion.type == KCCSKext && [KextHandler.sharedKextHandler existsInDB:suggestion.name]){
            [suggestStr appendFormat:@"<dt><a href=\"kext://%@\">%@</a></dt>", suggestion.name, suggestion.name];
        } else if(suggestion.url != nil){
            [suggestStr appendFormat:@"<dt><a href=\"%@\">%@</a></dt>", suggestion.url, suggestion.name];
        } else {
            [suggestStr appendFormat:@"<dt>%@</dt>", suggestion.name];
        }
        if(suggestion.text != nil){
            [suggestStr appendFormat:@"<dd>%@</dd>", suggestion.text];
        }
    }
    [suggestStr appendString:@"</dl>"];
    [_suggestedView.mainFrame loadHTMLString:[MarkdownToHTML.alloc initWithMarkdown:suggestStr].render baseURL:nil];
}

-(IBAction)closeSuggestion:(id)sender {
    [_suggestedPanel close];
}

-(IBAction)runTask:(NSButton *)sender {
    // Do not proceed if another task running
    [self closeTaskViwer:sender];
    if([NSFileManager.defaultManager fileExistsAtPath:KextHandler.lockFile]){
        NSRunCriticalAlertPanel(@"Invalid request!", @"A process is already running, wait until it is finished.", @"OK", nil, nil);
        return;
    }
    NSString *typeStr;
    switch (_taskType) {
        case KextInstall:
            typeStr = @"Installing";
            break;
        case KextUpdate:
            typeStr = @"Updating";
            break;
        case KextRemove:
            typeStr = @"Removing";
            break;
        default:
            NSRunCriticalAlertPanel(@"Invalid request!", @"The app doesn't know what to do with this type of request.", @"OK", nil, nil);
            return;
    }
    _spinner = [Spinner.alloc initWithTitle:[NSString stringWithFormat:@"%@ %@...", typeStr, kextConfig.kextName] AndSubtitle:@"Checking..."];
    [_spinner.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            [self runTaskBackground];
            [KextFinder.sharedKextFinder updateList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                // Run complete, now get result
                int status = EXIT_FAILURE;
                NSString *message = @"Failed executing the task. Please, try again.";
                NSDictionary *result = [HelperController.sharedHelper getFinalMessage];
                if(result != nil){
                    status = [(NSNumber *)[result objectForKey:@"status"] intValue];
                    message = [result objectForKey:@"message"];
                }
                if(status == EXIT_SUCCESS){
                    NSRunAlertPanel(@"Success!", @"%@", @"OK", nil, nil, message);
                } else {
                    NSRunCriticalAlertPanel(@"Failed!", @"%@", @"OK", nil, nil, message);
                }
                // Update kext list
                AppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
                [appDelegate updateTables];
                [appDelegate fetchKextInfo:self->kextConfig.name];
                return;
            });
        } @catch (NSException *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_spinner close];
                NSRunCriticalAlertPanel(e.name, @"%@", @"OK", nil, nil, e.reason);
                return;
            });
        }
    });
}

-(BOOL)isInstallable {
    return self->_installBtn.enabled;
}
-(BOOL)isUpdatable {
    return self->_updateBtn.enabled;
}
-(BOOL)isRemovable {
    return self->_removeBtn.enabled;
}

- (void) runTaskBackground {
    NSString *kextName = kextConfig.kextName;
    switch (_taskType) {
        case KextInstall:
            [HelperController.sharedHelper install:kextName];
            break;
        case KextUpdate:
            [HelperController.sharedHelper update:kextName];
            break;
        case KextRemove:
            [HelperController.sharedHelper remove:kextName];
            break;
        default:
            @throw [NSException exceptionWithName:@"Invalid request!" reason:@"The app doesn't know what to do with this type of request." userInfo:nil];
            return;
    }
    // Check for the background tasks until they are complete
    while([HelperController.sharedHelper isTaskRunning]) {
        [self performSelectorOnMainThread:@selector(updateTaskInfo) withObject:self waitUntilDone:YES];
        sleep(1);
    }
}

-(void)updateTaskInfo {
    @try {
        NSString *message = [HelperController.sharedHelper getLastMessage];
        if(message != nil){
            [_spinner setSubtitile:message];
            [_spinner.reload.window makeKeyAndOrderFront:self];
            [NSApp activateIgnoringOtherApps:YES];
        }
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
