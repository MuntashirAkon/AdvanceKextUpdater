//
//  KIHelperAgrumentController.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 13/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KIHelperAgrumentController.h"
#import "KextHandler.h"

@implementation KIHelperAgrumentController

+ (BOOL) install: (NSString *) kextName {
    return [self setArg:[NSString stringWithFormat:@"install %@", kextName]];
}

+ (BOOL) update: (NSString *) kextName {
    return [self setArg:[NSString stringWithFormat:@"update %@", kextName]];
}

+ (BOOL) remove: (NSString *) kextName {
    return [self setArg:[NSString stringWithFormat:@"remove %@", kextName]];
}

+ (BOOL) rebuildCache {
    return [self setArg:@"rebuildcache"];
}

+ (BOOL) repairPermissions {
    return [self setArg:@"repairpermissions"];
}

+ (BOOL) setArg: (NSString *) arg {
    return [arg writeToFile:[KextHandler.tmpPath stringByAppendingPathComponent:INPUT_FILE] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
