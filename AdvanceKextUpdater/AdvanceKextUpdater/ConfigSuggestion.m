//
//  ConfigSuggestion.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/31/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigSuggestion.h"
#import "utils.h"

@implementation ConfigSuggestion

@synthesize name;
@synthesize text;
@synthesize type;
@synthesize url;

- (instancetype) init { return self; }

+(NSArray<ConfigSuggestion *> *) createFromArray: (id) rawSuggestions {
    NSMutableArray<ConfigSuggestion *> *suggestions = NSMutableArray.array;
    if([rawSuggestions isKindOfClass:NSArray.class]){
        NSString *url, *name, *text;
        KCCSType type;
        for(NSDictionary *suggestion in rawSuggestions){
            name = [suggestion objectForKey:@"name"];
            if(isNull(name)) continue;
            text = [suggestion objectForKey:@"text"];
            url  = [suggestion objectForKey:@"url"];
            // Determine type
            if([name hasSuffix:@".app"]) type = KCCSApp;
            else if ([name hasSuffix:@".dmg"]) type = KCCSDMG;
            else if ([name hasSuffix:@".dylib"]) type = KCCSDYLIB;
            else if ([name hasSuffix:@".efi"]) type = KCCSEFI;
            else if ([name hasSuffix:@".pkg"] || [name hasSuffix:@".mpkg"]) type = KCCSPackage;
            else if ([name hasSuffix:@".sh"] || [name hasSuffix:@".command"]) type = KCCSShell;
            else type = KCCSKext;
            ConfigSuggestion *suggestionObj = [ConfigSuggestion new];
            suggestionObj.name = name;
            suggestionObj.text = (isNull(text) ? nil : text);
            suggestionObj.type = type;
            suggestionObj.url  = (isNull(url) ? nil : url);
            [suggestions addObject:suggestionObj];
        }
    }
    return suggestions.copy;
}

@end;
