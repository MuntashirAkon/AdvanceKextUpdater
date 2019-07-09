//
//  KextConfig.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/24/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextConfig_h
#define KextConfig_h

#import "ConfigAuthor.h"
#import "ConfigKextVersionControl.h"
#import "ConfigVersionControl.h"
#import "ConfigSuggestion.h"
#import "ConfigMacOSVersionControl.h"
#import "ConfigRequirments.h"
#import "ConfigBinary.h"
#import "ConfigTarget.h"

@class ConfigVersionControl;

// This serial is important!!!
typedef enum {
    KCCAllMatched,
    KCCSomeMatched,
    KCCNoneMatched,
    KCCSomeMatchedAllRestricted,
    KCCNoneMatchedAllRestricted,
    KCCSomeMatchedHWRestricted,
    KCCSomeMatchedSWRestricted,
    KCCNoneMatchedHWRestricted,
    KCCNoneMatchedSWRestricted,
} KextConfigCriteria;

@interface KextConfig: NSObject {
    NSString *configPath;
    id configParsed;
}

// Properties are in alphabetical order, based on Schema (OPTIONAL = null)
@property NSArray<ConfigAuthor *> * _Nonnull authors;             // Array √
@property ConfigBinary            * _Nonnull binaries;            // Dict
@property NSString                * _Nullable changes;             // String
@property NSArray<ConfigConflictKexts *> * _Nonnull conflict;     // Dict|null √
@property NSString                * _Nullable guide;               // String √ (maybe use a diff. object)
@property NSString                * _Nullable homepage;            // String|null √
@property ConfigHWRequirments     * _Nonnull hwRequirments;       // OPTIONAL Dict
@property NSString                * _Nonnull kextName;            // String √
@property NSArray<NSString *>     * _Nullable license;             // Array|String|null √
@property ConfigMacOSVersionControl * _Nonnull macOSVersion;
@property NSString                * _Nonnull name;                // String √
@property NSString                * _Nullable path;
@property NSArray<ConfigReplacedByKexts *> * _Nullable replacedBy; // Dict|null √
@property NSArray<ConfigRequiredKexts *> * _Nullable requirments;  // Dict|null √
@property NSString                * _Nullable shortDescription;    // String √
@property NSArray<ConfigSuggestion *> * _Nullable suggestions;     // Array|null √
@property ConfigSWRequirments     * _Nullable swRequirments;       // OPTIONAL Dict
@property NSArray<NSString *>     * _Nonnull tags;                // OPTIONAL String: comma separated √
@property ConfigTarget            * _Nonnull target;              // String: kSLE or kLE
@property NSDate                  * _Nonnull time;                // String: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD √
@property NSString                * _Nullable     url;
@property NSString                * _Nonnull version;             // String
@property ConfigVersionControl    * _Nullable versions;            // Array|null

- (instancetype _Nullable ) initWithConfig: (NSString * _Nonnull) configFile;
- (instancetype _Nullable ) initWithKextName: (NSString * _Nonnull) kextName;
- (instancetype _Nullable) initWithKextName: (NSString * _Nonnull) kextName URL: (NSURL * _Nonnull) configURL;
- (KextConfigCriteria) matchesAllCriteria;
@end

#endif /* KextConfig_h */
