//
//  PreferencesHandler.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 13/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "PreferencesHandler.h"
#import "../AdvanceKextUpdater/utils.h" // isRootUser
#import "ZSSUserDefaults/ZSSUserDefaults.h"
#import "../AdvanceKextUpdater/AKUDiskManager.h"

@implementation PreferencesHandler
@synthesize clover;
@synthesize kexts;
+(id)sharedPreferences {
    static PreferencesHandler *preferences = nil;
    static dispatch_once_t dispatch_token;
    dispatch_once(&dispatch_token, ^{
        preferences = [PreferencesHandler new];
    });
    return preferences;
}
-(instancetype)init {
    ZSSUserDefaults *defaults;
    defaults = [ZSSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[PreferencesHandler appDefaults]];
    NSDictionary *pref = [defaults dictionaryRepresentation];
    clover = [CloverPreference.alloc initWithDict:[pref objectForKey:@"Clover"]];
    kexts = [KextPreference.alloc initWithDict:[pref objectForKey:@"Kext"]];
    return self;
}

-(instancetype)reload {
    ZSSUserDefaults *defaults;
    defaults = [ZSSUserDefaults standardUserDefaults];
    NSDictionary *pref = [defaults dictionaryRepresentation];
    clover = [CloverPreference.alloc initWithDict:[pref objectForKey:@"Clover"]];
    kexts = [KextPreference.alloc initWithDict:[pref objectForKey:@"Kext"]];
    return self;
}

+(NSDictionary *)appDefaults{
    return @{
             @"Kext": @{
                     @"Check":@0, // Do not check
                     @"Update":@NO,
                     @"Replace":@NO,
                     @"Anywhere":@YES, // Otherwise just LE or SLE
                     @"Backup":@YES,
                     @"Exclude":@[]
                     },
             @"Clover": @{
                     @"Support":@NO,
                     @"Partition":@"",
                     @"Directories":@[
                             @"Other", @"10.6", @"10.7", @"10.8", @"10.9", @"10.10",
                             @"10.11", @"10.12", @"10.13", @"10.14"
                             ]
                     }
             };
}
@end

@implementation CloverPreference
@synthesize directories;
@synthesize partition;
@synthesize support;
-(instancetype)initWithDict: (NSDictionary *)cloverPref {
    directories = [cloverPref objectForKey:@"Directories"];
    partition = [cloverPref objectForKey:@"Partition"];
    support = ([[cloverPref objectForKey:@"Support"] integerValue] ? YES : NO);
    return self;
}
// Prefix directories if support for clover is enabled todo: check this on every request
-(void)prefixDirectories{
    if(support){
        AKUDiskManager *clover = [AKUDiskManager new];
        [clover setDisk:partition];
        NSString *mountPoint = [clover getMountPoint];
        if(mountPoint == nil){
            @throw [NSException exceptionWithName:@"Clover parition is not mounted" reason:@"You have enabled support for Clover parition, but for some reason this partition is not mounted. Please, try starting the app again or report us." userInfo:nil];
        }
        NSMutableArray<NSString *> *prefixedDirectories = NSMutableArray.array;
        for(NSString *directory in directories){
            [prefixedDirectories addObject:[NSString stringWithFormat:@"%@/EFI/CLOVER/kexts/%@", mountPoint, directory]];
        }
        directories = prefixedDirectories.copy;
    }
}
@end

@implementation KextPreference
@synthesize anywhere;
@synthesize backup;
@synthesize check;
@synthesize excluded;
@synthesize replace;
@synthesize update;
-(instancetype)initWithDict: (NSDictionary *)kextPref {
    anywhere = ([[kextPref objectForKey:@"Anywhere"] integerValue] ? YES : NO);
    backup = ([[kextPref objectForKey:@"Backup"] integerValue] ? YES : NO);
    check = (int)[[kextPref objectForKey:@"Check"] integerValue];
    excluded = [kextPref objectForKey:@"Exclude"];
    replace = ([[kextPref objectForKey:@"Replace"] integerValue] ? YES : NO);
    update = ([[kextPref objectForKey:@"Update"] integerValue] ? YES : NO);
    return self;
}
@end
