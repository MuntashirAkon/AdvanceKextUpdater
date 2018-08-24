//
//  KextConfigParser.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextConfigParser_h
#define KextConfigParser_h

#import "ConfigAuthor.h"

#define kLE  @"/Library/Extensions"
#define kSLE @"/System/Library/Extensions"

@interface KextConfigParser: NSObject {
@protected
    NSString *configPath;
    id configParsed;
@public // Properties are in alphabetical order, based on Schema (OPTIONAL = null)
    NSArray<ConfigAuthor *> *authors;           // Array √
    NSDictionary            *binaries;          // Dict
    NSString                *changes;           // String
    NSDictionary            *conflict;          // Dict|null
    NSString                *guide;             // String
    NSString                *homepage;          // String|null
    NSDictionary            *hwRequirments;     // OPTIONAL Dict
    NSString                *kextName;          // String
    NSString                *lastMacOSVersion;  // String|null
    id                       license;           // Array|String|null
    NSString                *name;              // String
    NSDictionary            *replacedBy;        // Dict|null
    NSDictionary            *requirments;       // Dict|null
    NSString                *shortDescription;  // String
    NSString                *sinceMacOSVersion; // String
    NSArray<NSDictionary *> *suggestions;       // Array|null
    NSDictionary            *swRequirments;     // OPTIONAL Dict
    NSArray<NSString *>     *tags;              // OPTIONAL String: comma separated
    NSString                *target;            // String: kSLE or kLE
    NSDate                  *time;              // String: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD √
    NSString                *version;           // String
    NSArray<NSDictionary *> *versions;          // Array|null
}

- (void) parseConfig;

@end

#endif /* KextConfigParser_h */
