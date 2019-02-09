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
    NSArray *tmpKexts = NSArray.array;
    // TODO: Add directories based on preferences
    tty([NSString stringWithFormat:@"kextfind --no-path"], &tmpKexts);
    _installedKexts = tmpKexts;
    return self;
}
-(BOOL)isInstalled: (NSString *)kextName {
    if(![kextName hasSuffix:@".kext"]){
        kextName = [kextName stringByAppendingPathExtension:@"kext"];
    }
    return [_installedKexts indexOfObject:kextName] != NSNotFound;
}

-(NSString *)findVersion: (NSString *)kextName {
    // TODO
    return nil;
}
-(NSArray<NSString *> *)findLocations: (NSString *)kextName {
    // TODO
    return nil;
}
+(void)updateList{
    // TODO
    return;
}
@end
