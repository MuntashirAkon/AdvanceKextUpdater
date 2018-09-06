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

@class ConfigVersionControl;

@interface KextConfig: NSObject {
    NSString *configPath;
    id configParsed;
}

// Properties are in alphabetical order, based on Schema (OPTIONAL = null)
@property NSArray<ConfigAuthor *> *authors;             // Array √
@property NSDictionary            *binaries;            // Dict
@property NSString                *changes;             // String
@property NSArray<ConfigConflictKexts *> *conflict;     // Dict|null √
@property NSString                *guide;               // String √ (maybe use a diff. object)
@property NSString                *homepage;            // String|null √
@property NSDictionary            *hwRequirments;       // OPTIONAL Dict
@property NSString                *kextName;            // String √
@property NSArray                 *license;             // Array|String|null √
@property ConfigMacOSVersionControl *macOSVersion;
@property NSString                *name;                // String √
@property NSString                *path;
@property NSArray<ConfigReplacedByKexts *> *replacedBy; // Dict|null √
@property NSArray<ConfigRequiredKexts *> *requirments;  // Dict|null √
@property NSString                *shortDescription;    // String √
@property NSArray<ConfigSuggestion *> *suggestions;     // Array|null √
@property NSDictionary            *swRequirments;       // OPTIONAL Dict
@property NSArray<NSString *>     *tags;                // OPTIONAL String: comma separated √
@property NSString                *target;              // String: kSLE or kLE
@property NSDate                  *time;                // String: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD √

@property NSString                *version;             // String
@property ConfigVersionControl    *versions;            // Array|null
@property NSString                *url;
- (instancetype) initWithConfig: (NSString *) configFile;
- (instancetype) initWithKextName: (NSString *) kextName;
- (instancetype) initWithKextName: (NSString *) kextName URL: (NSURL *) configURL;

@end

#endif /* KextConfig_h */
