//
//  main.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KextConfigParser.h"
#import "KextHandler.h"

int main(int argc, const char * argv[]) {
    // Create path in application support directory if not exists
    NSString *ASPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *AKUPath = [ASPath stringByAppendingPathComponent:@"AdvanceKextUpdater"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:AKUPath]){
        NSError *err;
        if(![fm createDirectoryAtPath:AKUPath withIntermediateDirectories:YES attributes:nil error:&err]){
            NSRunCriticalAlertPanel(@"Application Support isn't accessible!", @"Creating an important directory at Application Support directory failed!\nDetails: %@", nil, nil, nil, err);
            return (int)[err code];
        }
    }
    // Check for kext update
    [KextHandler checkForDBUpdate];
    if(![[NSFileManager defaultManager] fileExistsAtPath:[KextHandler kextDBPath]]) {
        NSRunCriticalAlertPanel(@"Updating Kext database failed!", @"Failed to update kext database, please check your internet connection and try again.", nil, nil, nil);
        return EXIT_FAILURE;
    }
//    KextConfigParser *configParser = [[KextConfigParser alloc] init];
//    [configParser parseConfig];
//    NSString *a = @"10.10.6";
//    NSString *b = @"10.11.6";
//    NSUInteger max = MAX([a length], [b length]);
    return 0;//NSApplicationMain(argc, argv);
}
