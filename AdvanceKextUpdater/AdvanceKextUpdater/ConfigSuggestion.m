//
//  ConfigSuggestion.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/31/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigSuggestion.h"

@implementation ConfigSuggestion

@synthesize name;
@synthesize text;

+(NSArray<ConfigSuggestion *> *) createFromArray: (NSArray *) rawSuggestions {
    NSMutableArray *suggestions = NSMutableArray.array;
    for(NSDictionary *suggestion in rawSuggestions){
        ConfigSuggestion *suggestionObj = [ConfigSuggestion.alloc init];
        [suggestionObj setName:[suggestion objectForKey:@"name"]];
        [suggestionObj setText:[suggestion objectForKey:@"text"]];
        [suggestions addObject:suggestionObj];
    }
    return suggestions.copy;
}

@end;
