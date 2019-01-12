//
//  PreferencesWindowController.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 29/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "../utils.h"
#import "../AppDelegate.h"
#import <DiskArbitration/DiskArbitration.h> // Disk

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController {
    @private
    IBOutlet NSPanel *_excludeKextPanel;
    // Panel outlets
    IBOutlet NSPopUpButton *_installedKextBtn;
    IBOutlet NSTableView *_excludeKextTable;
    IBOutlet NSArrayController *excludedKextsController;
    // Kext
    IBOutlet NSPopUpButton *_KextCheck;
    IBOutlet NSButton *_KextUpdate;
    IBOutlet NSButton *_KextReplace;
    IBOutlet NSButton *_KextAnywhere;
    IBOutlet NSButton *_KextBackup;
    // Clover
    IBOutlet NSButton *_CloverSupport;
    IBOutlet NSPopUpButton *_CloverPartition;
    IBOutlet NSButton *_CloverOSOthers;
    IBOutlet NSButton *_CloverOS10_6;
    IBOutlet NSButton *_CloverOS10_7;
    IBOutlet NSButton *_CloverOS10_8;
    IBOutlet NSButton *_CloverOS10_9;
    IBOutlet NSButton *_CloverOS10_10;
    IBOutlet NSButton *_CloverOS10_11;
    IBOutlet NSButton *_CloverOS10_12;
    IBOutlet NSButton *_CloverOS10_13;
    IBOutlet NSButton *_CloverOS10_14;
    // Others
    NSArray<NSString *> *updateTitles;
    NSMutableArray<NSString *> *cloverPartitionsInfo;
    NSMutableArray<NSString *> *BSDNames;
    NSUserDefaults *defaults;
    NSArray<NSString *> *installedKexts;
    NSMutableArray<NSString *> *excludedKexts;
    NSArray<NSString *> *excludedKextsFinal;
}

- (NSNibName) windowNibName {
    return @"Preferences";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    updateTitles = @[
        @"Do not check",
        @"Check on every boot",
        @"Check on every week",
        @"Check on every month"
    ];
    cloverPartitionsInfo = NSMutableArray.array;
    BSDNames = NSMutableArray.array;
    for(NSDictionary *partition in [self getListOfCloverInstallationLocation]){
        [cloverPartitionsInfo addObject:[NSString stringWithFormat:@"%@ (%@)", [partition objectForKey:@"BSDName"], [partition objectForKey:@"Label"]]];
        [BSDNames addObject:[partition objectForKey:@"BSDName"]];
    }
    [_KextCheck removeAllItems];
    [_CloverPartition removeAllItems];
    [_KextCheck addItemsWithTitles:updateTitles];
    [_CloverPartition addItemsWithTitles:cloverPartitionsInfo.copy];
    // Set values
    defaults = NSUserDefaults.standardUserDefaults;
    [self setPreferences];
    // Panel info
    [_excludeKextTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    installedKexts = [KextHandler.new listInstalledKext];
    [_installedKextBtn removeAllItems];
    [_installedKextBtn addItemsWithTitles:installedKexts];
}
- (void)close {
    // Kext
    NSDictionary *kext = @{
        @"Check":@(_KextCheck.indexOfSelectedItem),
        @"Update":@(_KextUpdate.state == NSOnState),
        @"Replace":@(_KextReplace.state == NSOnState),
        @"Anywhere":@(_KextAnywhere.state == NSOnState),
        @"Backup":@(_KextBackup.state == NSOnState),
        @"Exclude":excludedKextsFinal
    };
    [defaults setObject:kext forKey:@"Kext"];
    // Clover
    NSMutableArray *cloverDirs = NSMutableArray.array;
    if(_CloverOSOthers.state == NSOnState){ [cloverDirs addObject:@"Other"]; }
    if(_CloverOS10_6.state == NSOnState){ [cloverDirs addObject:@"10.6"]; }
    if(_CloverOS10_7.state == NSOnState){ [cloverDirs addObject:@"10.7"]; }
    if(_CloverOS10_8.state == NSOnState){ [cloverDirs addObject:@"10.8"]; }
    if(_CloverOS10_9.state == NSOnState){ [cloverDirs addObject:@"10.9"]; }
    if(_CloverOS10_10.state == NSOnState){ [cloverDirs addObject:@"10.10"]; }
    if(_CloverOS10_11.state == NSOnState){ [cloverDirs addObject:@"10.11"]; }
    if(_CloverOS10_12.state == NSOnState){ [cloverDirs addObject:@"10.12"]; }
    if(_CloverOS10_13.state == NSOnState){ [cloverDirs addObject:@"10.13"]; }
    if(_CloverOS10_14.state == NSOnState){ [cloverDirs addObject:@"10.14"]; }
    NSDictionary *clover = @{
        @"Support":@(_CloverSupport.state == NSOnState),
        @"Partition":[BSDNames objectAtIndex:_CloverPartition.indexOfSelectedItem],
        @"Directories":cloverDirs.copy
    };
    [defaults setObject:clover forKey:@"Clover"];
    /// @todo Warn user if an start-up mount script is required
    /// when the parition is not mounted by default
}

-(void)setPreferences{
    // Kext
    NSDictionary *kext = [defaults dictionaryForKey:@"Kext"];
    NSInteger k_c = [[kext objectForKey:@"Check"] integerValue];
    if(k_c >= 0 && k_c < updateTitles.count){ [_KextCheck selectItemAtIndex:k_c]; }
    [_KextUpdate    setState:([[kext objectForKey:@"Update"] integerValue] ? NSOnState : NSOffState)];
    [_KextReplace   setState:([[kext objectForKey:@"Replace"] integerValue] ? NSOnState : NSOffState)];
    [_KextAnywhere  setState:([[kext objectForKey:@"Anywhere"] integerValue] ? NSOnState : NSOffState)];
    [_KextBackup    setState:([[kext objectForKey:@"Backup"] integerValue] ? NSOnState : NSOffState)];
    excludedKexts = [NSMutableArray arrayWithArray:[kext objectForKey:@"Exclude"]];
    excludedKextsFinal = excludedKexts.copy;
    [excludedKextsController setContent:nil];
    for(NSString *kext in excludedKexts){
        [excludedKextsController addObject:@{@"kext": kext}];
    }
    [_excludeKextTable reloadData];
    // Clover
    NSDictionary *clover = [defaults dictionaryForKey:@"Clover"];
    [_CloverSupport setState:([[clover objectForKey:@"Support"] integerValue] ? NSOnState : NSOffState)];
    NSInteger c_i = [BSDNames indexOfObject:[clover objectForKey:@"Partition"]];
    if(c_i != NSNotFound){ [_CloverPartition selectItemAtIndex:c_i]; }
    for(NSString *c_f in [clover objectForKey:@"Directories"]){
        [self setOnStateUsingDirectoryName:c_f];
    }
}

-(void)setOnStateUsingDirectoryName:(NSString *)dirName{
    if([dirName isEqual:@"Other"]){ _CloverOSOthers.state = NSOnState; }
    else if([dirName isEqual:@"10.6"]){ _CloverOS10_6.state = NSOnState; }
    else if([dirName isEqual:@"10.7"]){ _CloverOS10_7.state = NSOnState; }
    else if([dirName isEqual:@"10.8"]){ _CloverOS10_8.state = NSOnState; }
    else if([dirName isEqual:@"10.9"]){ _CloverOS10_9.state = NSOnState; }
    else if([dirName isEqual:@"10.10"]){ _CloverOS10_10.state = NSOnState; }
    else if([dirName isEqual:@"10.11"]){ _CloverOS10_11.state = NSOnState; }
    else if([dirName isEqual:@"10.12"]){ _CloverOS10_12.state = NSOnState; }
    else if([dirName isEqual:@"10.13"]){ _CloverOS10_13.state = NSOnState; }
    else if([dirName isEqual:@"10.14"]){ _CloverOS10_14.state = NSOnState; }
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
    return result.copy;
}

-(IBAction)resetPreferences:(id)sender{
    [defaults removePersistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
    [defaults registerDefaults:AppDelegate.appDefaults];
    [self setPreferences];
    excludedKextsFinal = @[];
}

-(IBAction)showExcludeKextPanel:(id)sender{
    [self.window addChildWindow:_excludeKextPanel ordered:NSWindowAbove];
}

-(IBAction)addToExclusionList:(id)sender{
    NSString *kext = [_installedKextBtn titleOfSelectedItem];
    // Add this if not already
    NSInteger k_i = [excludedKexts indexOfObject:kext];
    if(k_i == NSNotFound){
        [excludedKextsController addObject:@{@"kext": kext}];
        [excludedKexts addObject:kext];
    }
}

-(IBAction)removeFromExclusionList:(id)sender{
    NSString *kext = [_installedKextBtn titleOfSelectedItem];
    // Add this if not already
    NSInteger k_i = [excludedKexts indexOfObject:kext];
    if(k_i != NSNotFound){
        [excludedKextsController removeObjectAtArrangedObjectIndex:k_i];
        [excludedKexts removeObjectAtIndex:k_i];
    }
}

-(IBAction)saveExcludedKextsAndClosePanel:(id)sender{
    excludedKextsFinal = excludedKexts.copy;
    [_excludeKextPanel close];
}

@end
