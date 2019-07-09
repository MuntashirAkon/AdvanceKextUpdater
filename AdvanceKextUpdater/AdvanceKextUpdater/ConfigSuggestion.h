//
//  ConfigSuggestion.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/31/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigSuggestion_h
#define ConfigSuggestion_h

/**
 * @abstract
 * Available types in suggestions
 */
typedef enum {
    /// .app extension
    KCCSApp,
    /// .dmg extension
    KCCSDMG,
    /// .dylib extension
    KCCSDYLIB,
    /// .efi extension
    KCCSEFI,
    /// .kext or no extension
    KCCSKext,
    /// .pkg, .mpkg extensions
    KCCSPackage,
    /// .sh, .command extensions
    KCCSShell,
} KCCSType;

@interface ConfigSuggestion: NSObject {}

@property NSString * _Nonnull name;
@property NSString * _Nullable text;
@property KCCSType type;
@property NSString * _Nullable url;

/**
 * @abstract
 * Create an array of ConfigSuggestion from the `suggest` section of config.json
 * @param suggestions
 * The `suggest` section
 * @return
 * An array of ConfigSuggestion, if no suggestion is available, array count is 0.
 */
+(NSArray<ConfigSuggestion *> * _Nonnull) createFromArray: (NSArray<NSDictionary *> * _Nullable) suggestions;

@end

#endif /* ConfigSuggestion_h */
