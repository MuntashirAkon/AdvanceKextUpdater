//
//  PreferencesWindowController.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 29/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "../utils.h"
#import <DiskArbitration/DiskArbitration.h> // Disk

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController {
    IBOutlet NSPopUpButton *update;
    IBOutlet NSPopUpButton *cloverPartition;
    IBOutlet NSButton *replace;
    NSMutableDictionary *settings;
    NSArray<NSString *> *updateTitles;
    NSMutableArray<NSString *> *cloverPartitionsInfo;
    NSMutableArray<NSString *> *BSDNames;
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
    settings = NSMutableDictionary.dictionary;
    cloverPartitionsInfo = NSMutableArray.array;
    BSDNames = NSMutableArray.array;
    for(NSDictionary *partition in [self getListOfCloverInstallationLocation]){
        [cloverPartitionsInfo addObject:[NSString stringWithFormat:@"%@ (%@)", [partition objectForKey:@"BSDName"], [partition objectForKey:@"Label"]]];
        [BSDNames addObject:[partition objectForKey:@"BSDName"]];
    }
    [update removeAllItems];
    [cloverPartition removeAllItems];
    [update addItemsWithTitles:updateTitles];
    [cloverPartition addItemsWithTitles:cloverPartitionsInfo.copy];
    /// @todo load currently running config
}
- (void)close {
    NSLog(@"Check: %@", [update titleOfSelectedItem]);
    NSLog(@"Clover: %@", [cloverPartition titleOfSelectedItem]);
    NSLog(@"Replace: %@", [replace title]);
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
@end
