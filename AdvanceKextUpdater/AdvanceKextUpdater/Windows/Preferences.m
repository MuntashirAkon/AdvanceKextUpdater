//
//  Preferences.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 30/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import "Preferences.h"
#import "../utils.h"
#import "../KextHandler.h"

@implementation Preferences {}
- (void) close {
    [super close];
    [self.windowController close];
}

-(IBAction)openBackupLocation:(id)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        tty([NSString stringWithFormat:@"open '%@'", KextHandler.kextBackupPath], nil);
    });
}
@end
