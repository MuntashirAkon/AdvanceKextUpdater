//
//  KextConfigParser.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextConfigParser.h"

@implementation KextConfigParser
- (instancetype) init {
    configPath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
//    NSLog(@"Config path: %@", configPath);
    return self;
}
- (void) parseConfig {
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    NSError *configError;
    if (@available(macOS 10.7, *)) {
        configParsed = [NSJSONSerialization JSONObjectWithData:[config dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&configError];
//        NSLog(@"Parsed config: %@", configParsed);
//        NSLog(@"%d", [configParsed objectForKey:@"versions"] == [NSNull null]);
    } else {
        // Fallback on earlier versions
        // Use JSONKit: https://github.com/johnezang/JSONKit
        return; // For now
    }
    // Associate parsed info with the public methods
    authors     = [ConfigAuthor createFromArrayOfDictionary:[configParsed objectForKey:@"authors"]];
    binaries    = [configParsed objectForKey:@"bin"];       // Needs own class
    changes     = [configParsed objectForKey:@"changes"];   // Markdown
    conflict    = [configParsed objectForKey:@"conflict"];  // Needs own class
    guide       = [configParsed objectForKey:@"guide"];     // Markdown
    homepage    = [configParsed objectForKey:@"homepage"];
    hwRequirments     = [configParsed objectForKey:@"hw"];  // Needs own class
    kextName    = [configParsed objectForKey:@"kext"];
    lastMacOSVersion  = [configParsed objectForKey:@"last"];// part of macOS version checker class
    license     = [configParsed objectForKey:@"license"];
    name        = [configParsed objectForKey:@"name"];
    replacedBy  = [configParsed objectForKey:@"replaced_by"];// Needs own class
    requirments = [configParsed objectForKey:@"requirments"];// Needs own class
    shortDescription  = [configParsed objectForKey:@"description"]; // Markdown
    sinceMacOSVersion = [configParsed objectForKey:@"since"];// part of macOS version checker class
    suggestions = [configParsed objectForKey:@"suggest"];   // Needs own class
    swRequirments = [configParsed objectForKey:@"sw"];      // Needs own class
    tags        = [[configParsed objectForKey:@"tags"] componentsSeparatedByString:@","]; // Trim too???
    target      = [configParsed objectForKey:@"target"];    // Set based on macOS version
    time        = [NSDate dateWithNaturalLanguageString:[configParsed objectForKey:@"time"]];
    version     = [configParsed objectForKey:@"version"]; // Needs own class (in relation with versions)
    versions    = [configParsed objectForKey:@"versions"];  // Needs own class
}



@end
