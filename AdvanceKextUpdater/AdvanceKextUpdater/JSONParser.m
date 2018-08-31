//
//  JSONParser.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/31/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONParser.h"

@implementation JSONParser

+ (id) parseFromFile: (NSString *) jsonFile {
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    return [self parse:jsonString];
}

+ (id) parse: (NSString *) jsonString {
    NSError *err;
    return [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
}

@end
