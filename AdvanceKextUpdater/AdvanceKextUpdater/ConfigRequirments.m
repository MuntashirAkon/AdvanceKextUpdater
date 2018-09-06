//
//  ConfigRequirments.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/6/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigRequirments.h"

@implementation ConfigRequirments
@synthesize restrictInstall;
@end

@implementation ConfigSWRequirments
@synthesize kernel_max;
@synthesize kernel_min;

- (instancetype) initWithObject: (id) swRequirments {
    self = [super init];
    // Initialize values
    [self setRestrictInstall:YES];
    kernel_min = nil;
    kernel_max = nil;
    if([swRequirments isKindOfClass:NSDictionary.class]){
        id tmpObj = [swRequirments objectForKey:@"restrict"];
        // Check for restrict first
        if(tmpObj != NSNull.null)
            [self setRestrictInstall:(BOOL)tmpObj == YES ? YES : NO];
        // Add kernel min, max
        tmpObj = [swRequirments objectForKey:@"kernel"];
        if([tmpObj isKindOfClass:NSString.class]) {
            kernel_min = tmpObj;
            kernel_max = nil;
        } else if([tmpObj isKindOfClass:NSDictionary.class]) {
            kernel_min = [tmpObj objectForKey:@"min"];
            kernel_max = [tmpObj objectForKey:@"max"];
        }
    }
    return self;
}
@end

@implementation ConfigHWRequirments
@synthesize audio_codecs;
@synthesize connected_ids;
@synthesize cpu_regex;
@synthesize gpu_regex;
@synthesize pci_ids;

- (instancetype) initWithObject: (id) hwRequirments {
    self = [super init];
    // Initialize values
    [self setRestrictInstall:YES];
    audio_codecs  = NSArray.array;
    connected_ids = NSArray.array;
    cpu_regex = NSArray.array;
    gpu_regex = NSArray.array;
    pci_ids   = NSArray.array;
    if([hwRequirments isKindOfClass:NSDictionary.class]){
        id tmpObj = [hwRequirments objectForKey:@"restrict"];
        // Check for restrict first
        if(tmpObj != NSNull.null)
            [self setRestrictInstall:(BOOL)tmpObj == YES ? YES : NO];
        // audio codecs
        audio_codecs  = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_audio"]];
        connected_ids = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_connected"]];
        cpu_regex = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_cpu"]];
        gpu_regex = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_gpu"]];
        pci_ids   = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_pci"]];
    }
    return self;
}

- (NSArray *) strOrArrayOrNullToArray: (id) strOrArrayOrNull {
    NSMutableArray *tmpArr = NSMutableArray.array;
    if([strOrArrayOrNull isKindOfClass:NSString.class]){
        [tmpArr addObject:strOrArrayOrNull];
    } else if([strOrArrayOrNull isKindOfClass:NSArray.class]){
        return [strOrArrayOrNull copy];
    }
    return [tmpArr copy];
}
@end
