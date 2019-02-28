//
//  KextFinder.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "KextFinder.h"
#import "utils.h"
#import "../Shared/PreferencesHandler.h"
#import "AKUDiskManager.h"

@implementation KextFinder

+(id)sharedKextFinder {
    static KextFinder *kextFinder = nil;
    static dispatch_once_t dispatch_token;
    dispatch_once(&dispatch_token, ^{
        kextFinder = [KextFinder new];
    });
    return kextFinder;
}

-(instancetype)init {
    [self updateList];
    return self;
}
-(BOOL)isInstalled: (NSString *)kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    NSString *regex = [NSString stringWithFormat:@".*%@$", kextName];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    NSArray *matches = [_installedKexts filteredArrayUsingPredicate:filter];
    return matches.count > 0;
}

-(NSString *)findVersion: (NSString *)kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    NSArray *kextLoc = [self findLocations:kextName];
    NSString *version;
    NSString *min_version = [self _get_version:[kextLoc firstObject]];
    for (NSUInteger i = 1; i<kextLoc.count; ++i) {
        version = [self _get_version:[kextLoc objectAtIndex:i]];
        if([version.shortenedVersionNumberString compare:min_version.shortenedVersionNumberString options:NSNumericSearch] == NSOrderedAscending){
            min_version = version;
        }
    }
    return min_version;
}
-(NSArray<NSString *> *)findLocations: (NSString *)kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    NSString *regex = [NSString stringWithFormat:@".*%@$", kextName];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    NSArray *matches = [_installedKexts filteredArrayUsingPredicate:filter];
    return matches;
}
-(void)updateList{
    NSArray *tmpKexts = NSArray.array;
    NSString *directories = NSString.string;
    CloverPreference *clover = [PreferencesHandler.sharedPreferences clover];
    if(clover.support){
        directories = [clover.directories componentsJoinedByString:@" "];
    }
    tty([NSString stringWithFormat:@"kextfind %@ %@ %@", kSLE, kLE, directories], &tmpKexts);
    _installedKexts = tmpKexts;
}

-(NSString * _Nullable)_get_version: (NSString *)kextLocation{
    NSString *version;
    if(kextLocation == nil) {
        @throw [NSException exceptionWithName:@"KextNotInstalled" reason:@"The requested kext is not installed. So, can't get a version for a kext that's not installed!" userInfo:nil];
    }
    NSString *plist = [NSString stringWithFormat:@"%@/Contents/Info.plist", kextLocation];
    if(![NSFileManager.defaultManager fileExistsAtPath:plist]){
        @throw [NSException exceptionWithName:@"InfoPlistNotFound" reason:@"The Info.plist of the requested kext is not found. So, can't get a version!" userInfo:nil];
    }
    version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleShortVersionString"];
    if(version == nil){
        version = [[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"CFBundleVersion"];
    }
    return version;
}
@end
