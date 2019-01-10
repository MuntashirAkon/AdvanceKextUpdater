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
        [NSWorkspace.sharedWorkspace openFile:KextHandler.kextBackupPath withApplication:nil andDeactivate:YES];
    });
}

-(IBAction)clearCaches:(id)sender{
    NSInteger action = NSRunCriticalAlertPanel(@"Are you sure?", @"Are you sure want to clear caches? This action cannot be undone.", @"Clear Caches", @"Cancel", nil);
    if(action == NSAlertDefaultReturn){
        tty([NSString stringWithFormat:@"rm -Rf '%@'/* '%@'/*", KextHandler.kextCachePath, KextHandler.guideCachePath], nil);
        // Send confirmation message?
    }
}

-(IBAction)clearBackups:(id)sender{
    NSInteger action = NSRunCriticalAlertPanel(@"Are you sure?", @"Are you sure want to clear backups? This action cannot be undone.", @"Clear Backups", @"Cancel", nil);
    if(action == NSAlertDefaultReturn){
        tty([NSString stringWithFormat:@"rm -Rf '%@'/*", KextHandler.kextBackupPath], nil);
        // Send confirmation message?
    }
}
@end
