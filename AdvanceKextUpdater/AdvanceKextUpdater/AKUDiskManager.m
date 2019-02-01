//
//  AKUDiskManager.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 1/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "AKUDiskManager.h"
#import <DiskArbitration/DiskArbitration.h> // Disk
#import "utils.h"
#import "Task.h"

@implementation AKUDiskManager
-(instancetype)init{
    _diskBSD = nil;
    return self;
}

-(void)setDisk:(NSString *)disk{
    _diskBSD = disk;
    [self reloadDiskInfo];
}

-(BOOL)isMounted{
    if(_diskBSD == nil) @throw [NSException exceptionWithName:@"Disk not set" reason:@"No specific BSD name is set" userInfo:nil];
    [self reloadDiskInfo];
    return !isNull([_diskData objectForKey:@"Path"]);
}

-(NSString * _Nullable)getMountPoint{
    if(_diskBSD == nil) @throw [NSException exceptionWithName:@"Disk not set" reason:@"No specific BSD name is set" userInfo:nil];
    return ([self isMounted] ? [_diskData objectForKey:@"Path"] : nil);
}

-(BOOL)mountVolume{
    if(_diskBSD == nil) @throw [NSException exceptionWithName:@"Disk not set" reason:@"No specific BSD name is set" userInfo:nil];
    if([self isMounted]) return YES;
    if(tty([NSString stringWithFormat:@"diskutil mount %@", _diskBSD], nil) != EXIT_SUCCESS){
        @try {
            [AScript adminExec:[NSString stringWithFormat:@"diskutil mount %@", _diskBSD]];
            [self reloadDiskInfo];
            return YES;
        } @catch (NSError *e) {
            printf("Error: %s\n", [[[e userInfo] objectForKey:@"details"] UTF8String]);
        }
        return NO;
    }
    [self reloadDiskInfo];
    return YES;
}

-(void)reloadDiskInfo{
    NSMutableArray *BSDNames = NSMutableArray.array;
    if(_diskBSD == nil){
        tty(@"cd /dev && ls disk*s*", &BSDNames);
    }else{
        [BSDNames addObject:_diskBSD];
    }
    NSMutableArray *result = NSMutableArray.array;
    for(NSString *BSDName in BSDNames) {
        int             err = 0;
        DADiskRef       disk = NULL;
        DASessionRef    session;
        CFDictionaryRef diskInfo = NULL;
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
                    NSString *path = [NSString stringWithUTF8String:buf];
                    [result addObject:@{
                        @"BSDName": BSDName,
                        @"Label": (__bridge NSString *)volume_label,
                        @"Path": (path == nil ? @"" : path)
                    }];
                }
            }
        }
        if (diskInfo != NULL) { CFRelease(diskInfo); }
        if (disk != NULL) { CFRelease(disk); }
        if (session != NULL) { CFRelease(session); }
    }
    _diskInfo = [result copy];
    if(_diskBSD != nil){
        for(NSDictionary *info in result){
            if([[info objectForKey:@"BSDName"] isEqualToString:_diskBSD]){
                _diskData = info;
                break;
            }
        }
    }
}
@end
