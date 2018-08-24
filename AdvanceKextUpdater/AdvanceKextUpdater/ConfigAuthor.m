//
//  ConfigAuthor.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigAuthor.h"

@implementation ConfigAuthor

- (instancetype) init {
    return self;
}

- (instancetype) initWithDictionary: (NSDictionary *) AuthorDictionary {
    name     = [AuthorDictionary objectForKey:@"name"];
    email    = [AuthorDictionary objectForKey:@"email"];
    homepage = [AuthorDictionary objectForKey:@"homepage"];
    return self;
}

+ (NSArray *) createFromArrayOfDictionary: (NSArray *) AuthorsDictionary {
    NSMutableArray *authors;
    for (NSDictionary *author in AuthorsDictionary) {
        [authors addObject:[[ConfigAuthor alloc] initWithDictionary:author]];
    }
    return [NSMutableArray copy];
}

@end
