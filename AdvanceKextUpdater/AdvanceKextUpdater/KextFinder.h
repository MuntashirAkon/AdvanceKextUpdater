//
//  KextFinder.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @interface KextFinder
/// @abstract
/// Find whether the kext is installed, its version and locations
/// @discussion
/// KextFinder is a singleton object to find whether a kext is installed.
/// And if installed, it can be used to get its version and install
/// locations.
@interface KextFinder : NSObject
/// A list of installed kexts (with system kexts)
@property NSArray<NSString *> *installedKexts;
/// @abstract
/// KextFinder singleton caller
+(id)sharedKextFinder;
/// @abstract
/// Find whether the kext is installed
/// @param kextName
/// Name of the kext with or without the "kext" extension
/// @return
/// YES if installed, NO otherwise
-(BOOL)isInstalled: (NSString *)kextName;
/// @abstract
/// Find the installed version of a kext (if installed)
/// @param kextName
/// Name of the kext with or without the "kext" extension
/// @return
/// Kext version, nil if not installed or version not present in the Info.plist
-(NSString * _Nullable)findVersion: (NSString *)kextName;
/// @abstract
/// Find the location(s) of the kext (if installed)
/// @param kextName
/// Name of the kext with or without the "kext" extension
/// @return
/// Kext installation location(s)
-(NSArray<NSString *> * _Nonnull)findLocations: (NSString *)kextName;
/// @abstract
/// Update installed kext list (recommended after an action)
-(void)updateList;
@end

NS_ASSUME_NONNULL_END
