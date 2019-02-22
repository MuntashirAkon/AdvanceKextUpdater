//
//  PreferencesHandler.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 13/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    KextUpdateDoNotCheck,
    KextUpdateCheckOnBoot,
    KextUpdateCheckWeekly,
    KextUpdateCheckMonthly
} KextUpdatePref;

@interface CloverPreference : NSObject
///
/// A list of directories
@property (readonly) NSArray<NSString *> *directories;
///
/// Clover partition
@property (readonly) NSString *partition;
///
/// Whether support for Clover is enabled
@property (readonly) BOOL support;

-(instancetype)initWithDict: (NSDictionary *)cloverPref;
-(void)prefixDirectories;
@end

@interface KextPreference : NSObject
///
/// Whether to update/delete kext from everywhere instead of LE or SLE
@property (readonly) BOOL anywhere;
///
/// Whether to backup the existing kext during update
@property (readonly) BOOL backup;
///
/// Whether to check for update
@property (readonly) KextUpdatePref check;
///
/// Excluded kexts
@property (readonly) NSArray<NSString *> *excluded;
///
/// Whether to replace old kext(s) with new one if the kext is replaced by a new kext
@property (readonly) BOOL replace;
///
/// Whether to update kexts automatically (except the excluded)
@property (readonly) BOOL update;

-(instancetype)initWithDict: (NSDictionary *)kextPref;
@end

@interface PreferencesHandler : NSObject
+(id)sharedPreferences;
///
/// A wrapper for clover preferences
@property (readonly) CloverPreference *clover;
///
/// A wrapper for kext-related preferences
@property (readonly) KextPreference *kexts;
///
/// Reload preferences
-(instancetype)reload;
///
/// Default preferences
+(NSDictionary *)appDefaults;
@end

NS_ASSUME_NONNULL_END
