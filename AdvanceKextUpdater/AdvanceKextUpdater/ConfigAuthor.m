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
@synthesize name;
@synthesize email;
@synthesize homepage;

- (instancetype) init {
    return self;
}

+ (NSArray *) createFromArrayOfDictionary: (NSArray *) AuthorsDictionary {
    NSMutableArray *authors = [NSMutableArray array];
    for (NSDictionary *author in AuthorsDictionary) {
        ConfigAuthor *authorObj = [[ConfigAuthor alloc] init];
        [authorObj setName:[author objectForKey:@"name"]];
        [authorObj setEmail:[author objectForKey:@"email"]];
        [authorObj setHomepage:[author objectForKey:@"homepage"]];
        [authors addObject:authorObj];
    }
    return [authors copy];
}

@end
