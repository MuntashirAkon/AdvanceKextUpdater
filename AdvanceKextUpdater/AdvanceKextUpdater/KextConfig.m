//
//  KextConfig.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/24/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextConfig.h"
#import "JSONParser.h"
#import "KextHandler.h"
#import "Task.h"

@implementation KextConfig
- (instancetype) initWithConfig: (NSString *) configFile {
    configPath = configFile;
    self.path = [configPath stringByDeletingLastPathComponent];
    self.url  = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        return [self parseConfig] ? self : nil;
    else return nil;
}

- (instancetype) initWithKextName: (NSString *) kextName {
    kextName = [kextName stringByDeletingPathExtension];
    configPath = [self searchConfigPath:kextName];
    self.path = [configPath stringByDeletingLastPathComponent];
    self.url  = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        return [self parseConfig] ? self : nil;
    else return nil;
}

// BUG ALERT!!!
- (instancetype) initWithKextName: (NSString *) kextName URL: (NSURL *) configURL {
    kextName = [kextName stringByDeletingPathExtension];
    configPath = [self appendConfigJSON:[[KextHandler kextCachePath] stringByAppendingPathComponent:kextName]];
    // Save config.json from URL to cache
    [URLTask get:configURL toFile:configPath supress:YES];
    self.path = [configPath stringByDeletingLastPathComponent];
    self.url  = [configURL URLByDeletingLastPathComponent].absoluteString;
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        return [self parseConfig] ? self : nil;
    else return nil;
}

- (BOOL) parseConfig {
    @try {
    configParsed = [JSONParser parseFromFile:configPath];
    // Associate parsed info with the public methods
    self.authors     = [ConfigAuthor createFromArrayOfDictionary:[configParsed objectForKey:@"authors"]];
    self.binaries    = [configParsed objectForKey:@"bin"];       // Needs own class
    self.changes     = [configParsed objectForKey:@"changes"];
    self.conflict    = [ConfigConflictKexts initWithDictionaryOrNull:[configParsed objectForKey:@"conflict"]];
    self.guide       = [configParsed objectForKey:@"guide"];
    self.homepage    = [configParsed objectForKey:@"homepage"];
    self.hwRequirments = [ConfigHWRequirments.alloc initWithObject:[configParsed objectForKey:@"hw"]];
    self.kextName    = [configParsed objectForKey:@"kext"];
    self.license     = [self licenseToArrayOfLicense:[configParsed objectForKey:@"license"]];
    self.macOSVersion = [ConfigMacOSVersionControl.alloc initWithHighest:[configParsed objectForKey:@"last"] andLowest:[configParsed objectForKey:@"since"]];
    self.name        = [configParsed objectForKey:@"name"];
    self.replacedBy  = [ConfigReplacedByKexts initWithDictionaryOrNull:[configParsed objectForKey:@"replaced_by"]];
    self.requirments = [ConfigRequiredKexts initWithDictionaryOrNull:[configParsed objectForKey:@"require"]];
    self.shortDescription  = [configParsed objectForKey:@"description"];
    self.suggestions = [ConfigSuggestion createFromArray:[configParsed objectForKey:@"suggest"]];
    self.swRequirments = [ConfigSWRequirments.alloc initWithObject:[configParsed objectForKey:@"sw"]];
    self.tags        = [self tagsFromString:[configParsed objectForKey:@"tags"]];
    self.target      = [configParsed objectForKey:@"target"];    // Set based on macOS version
    self.time        = [NSDate dateWithNaturalLanguageString:[configParsed objectForKey:@"time"]];
    self.version     = [configParsed objectForKey:@"version"];
    self.versions    = [ConfigVersionControl.alloc initWithSelfConfig:self andOtherVersions:[configParsed objectForKey:@"versions"]];
        return YES;
    } @catch (NSException *e) {
        return NO;
    }
}

- (NSArray *) licenseToArrayOfLicense: (id) license {
    NSMutableArray *licenses = [NSMutableArray array];
    if([license isKindOfClass:[NSString class]]) {
        [licenses addObject:license];
    } else if ([license isKindOfClass:[NSArray class]]) {
        licenses = license;
    }
    return [licenses copy];
}

- (NSArray *) tagsFromString: (id) tagString {
    NSMutableArray *tags = NSMutableArray.array;
    if(tagString != [NSNull null]) {
        NSArray *tagsWithSpaces = [tagString componentsSeparatedByString:@","];
        for(NSString *tag in tagsWithSpaces){
            [tags addObject:[tag stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
        }
    }
    return tags.copy;
}

/**
 * Check if all the criteria to install kext have been met
 *
 * @return KextConfigCriteria
 */
- (KextConfigCriteria) matchesAllCriteria {
    short checks = 0;
    const short total_checks = 3;
    BOOL hw_restricted = NO;
    BOOL sw_restricted = NO;
    // Check if this version is installable
    if([self.macOSVersion installableInCurrentVersion]){
        ++checks;
    }
    // Check if hw requirments matched
    if([self.hwRequirments matchCriteria]){
        ++checks;
    } else if ([self.hwRequirments restrictInstall]){
        hw_restricted = YES;
    }
    // Check if sw requirments matched
    if([self.swRequirments matchCriteria]){
        ++checks;
    } else if ([self.swRequirments restrictInstall]){
        sw_restricted = YES;
    }
    if(checks == total_checks) return KCCAllMatched;
    else if (checks == 0) { // None matched
        if(hw_restricted && sw_restricted) return KCCNoneMatchedAllRestricted;
        else if(hw_restricted) return KCCNoneMatchedHWRestricted;
        else if(sw_restricted) return KCCNoneMatchedSWRestricted;
        else return KCCNoneMatched;
    } else {
        if(hw_restricted && sw_restricted) return KCCSomeMatchedAllRestricted;
        else if(hw_restricted) return KCCSomeMatchedHWRestricted;
        else if(sw_restricted) return KCCSomeMatchedSWRestricted;
        else return KCCSomeMatched;
    }
    return checks;
}

/**
 * This method will search for config files in the following folders (${kextName} as subfolder and ~/Library/Application Support/AdvanceKextUpdater as ${ROOT}):
 * - ${ROOT}/kext_db
 * - ${ROOT}/Cache/kexts
 * - tmp/AdvanceKextUpdater/kexts
 *
 * @return config.json file
 */
- (NSString *) searchConfigPath: (NSString *) kextName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *kextPath = [[KextHandler kextDBPath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    kextPath = [[KextHandler kextCachePath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    kextPath = [[KextHandler kextTmpPath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    return nil;
}

- (NSString *) appendConfigJSON: (NSString *) kextPath {
    return [[kextPath stringByAppendingPathComponent:@"config"] stringByAppendingPathExtension:@"json"];
}

@end
