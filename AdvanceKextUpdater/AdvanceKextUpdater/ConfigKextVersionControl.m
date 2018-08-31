//
//  ConfigKextVersionControl.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/27/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigKextVersionControl.h"

@implementation ConfigKextVersionControl
@synthesize kextName;

- (instancetype) init {
    return self;
}
- (void) setVersionString: (NSString *) version {
    if(version == nil){ // nil = wildcard (*)
        self.version = @"*";
    } else if([version hasSuffix:@"^"]) {
        self.uptoLatest = YES;
        self.version = [version substringToIndex:[version length]-1];
    } else {
        self.version = version;
    }
}
@end

@implementation ConfigRequiredKexts
- (instancetype) init {
    return [super init];
}

+ (NSArray<ConfigRequiredKexts *> *) initWithDictionaryOrNull: (id) requiredKexts {
    NSMutableArray<ConfigRequiredKexts *> *kexts = [NSMutableArray array];
    if(requiredKexts != [NSNull null]){
        for(NSString *kext in requiredKexts){
            ConfigRequiredKexts *tmpKext = [[ConfigRequiredKexts alloc] init];
            [tmpKext setKextName:kext];
            [tmpKext setVersionString:[requiredKexts objectForKey:kext]];
            [kexts addObject:tmpKext];
        }
    }
    return [kexts copy];
}

@end

@implementation ConfigConflictKexts
- (instancetype) init {
    return [super init];
}

+ (NSArray<ConfigConflictKexts *> *) initWithDictionaryOrNull: (id) conflictKexts {
    NSMutableArray<ConfigConflictKexts *> *kexts = [NSMutableArray array];
    if(conflictKexts != [NSNull null]  && [conflictKexts objectForKey:@"kexts"] != [NSNull null]){
        NSDictionary *conflictKextsList = [conflictKexts objectForKey:@"kexts"];
        for(NSString *kext in conflictKextsList){
            ConfigConflictKexts *tmpKext = [[ConfigConflictKexts alloc] init];
            [tmpKext setAction:[conflictKexts objectForKey:@"action"]];
            [tmpKext setKextName:kext];
            [tmpKext setVersionString:[conflictKextsList objectForKey:kext]];
            [kexts addObject:tmpKext];
        }
    }
    return [kexts copy];
}

@end

@implementation ConfigReplacedByKexts
@synthesize sinceMacOSVersion;
- (instancetype) init {
    return [super init];
}

+ (NSArray<ConfigReplacedByKexts *> *) initWithDictionaryOrNull: (id) replacedByKexts {
    NSMutableArray<ConfigReplacedByKexts *> *kexts = [NSMutableArray array];
    if(replacedByKexts != [NSNull null] && [replacedByKexts objectForKey:@"kexts"] != [NSNull null]){
        NSDictionary *replacedByKextList = [replacedByKexts objectForKey:@"kexts"];
        for(NSString *kext in replacedByKextList){
            ConfigReplacedByKexts *tmpKext = [[ConfigReplacedByKexts alloc] init];
            [tmpKext setSinceMacOSVersion:[replacedByKexts objectForKey:@"since"]];
            [tmpKext setKextName:kext];
            [tmpKext setVersionString:[replacedByKextList objectForKey:kext]];
            [kexts addObject:tmpKext];
        }
    }
    return [kexts copy];
}
@end

