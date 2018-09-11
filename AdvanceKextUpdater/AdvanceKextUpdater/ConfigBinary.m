//
//  ConfigBinary.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigBinary.h"

@implementation BinaryHandler
@synthesize url;
@synthesize script;
@synthesize location;

- (instancetype) initWithDict: (id) binaryDict {
    if(binaryDict == [NSNull null]) return nil;
    self->url = [binaryDict objectForKey:@"url"];
    self->script = [binaryDict objectForKey:@"script"];
    self->location = [binaryDict objectForKey:@"loc"];
    return self;
}
@end

@implementation ConfigBinary
@synthesize recommended;
@synthesize dev;
@synthesize rel;
@synthesize postInstallScript;

- (instancetype) initWithDict: (NSDictionary *) binaryDict {
    NSString *recommended = [binaryDict objectForKey:@"recommend"];
    self->dev = [BinaryHandler.alloc initWithDict:[binaryDict objectForKey:CB_DEBUG]];
    self->rel = [BinaryHandler.alloc initWithDict:[binaryDict objectForKey:CB_RELEASE]];
    // RELEASE is the top priority
    if([binaryDict objectForKey:CB_DEBUG] != nil && recommended != nil && [recommended isEqual:CB_DEBUG]) {
        self->recommended = self.dev;
    } else {
        self->recommended = self.rel;
    }
    if(self->recommended == nil) @throw [NSException exceptionWithName:@"ConfigBinaryException" reason:@"The recommended/rel binary doesn't exist!" userInfo:nil];
    self->postInstallScript = [binaryDict objectForKey:@"post-install"];
    return self;
}
@end
