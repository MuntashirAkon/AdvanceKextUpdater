//
//  KextInstaller.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 12/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextInstaller.h"
#import "KextHandler.h"

// Exit codes
#define PI_ALL_DONE 0
#define PI_INSTALL  1
#define PI_FAILURE  2
#define PI_NO_SCRIPT 3 // Private code

@implementation KextInstaller

// No default init
- (instancetype) init { return nil; }

+ launchDaemonPlistFile {
    return [[@"/Library/LaunchDaemons/" stringByAppendingPathComponent:launchDaemonName] stringByAppendingPathExtension:@"plist"];
}
@end
