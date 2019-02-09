//
//  AppDelegate.m
//  KextStatViewer
//
//  Created by Muntashir Al-Islam on 4/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "AppDelegate.h"
#import "../../AdvanceKextUpdater/utils.h"

typedef enum {
    KSMatched,
    KSIndex,
    KSRefs,
    KSAddress,
    KSSize,
    KSWired,
    KSBundleId,
    KSVersion,
    KSUUID,
    KSIndexes
} KextStatGroups;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property IBOutlet NSTableView *kextStatTable;
@property IBOutlet NSTextView *kextStatInfo;
@property IBOutlet NSArrayController *kextStatData;
@property NSRegularExpression *kextStatExpression;
@property NSMutableDictionary *kextStatDataDict;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *kextStat = NSArray.array;
    _kextStatExpression = [NSRegularExpression regularExpressionWithPattern:@"\\s*(\\d+)\\s+(\\d+)\\s+(0x[0-9a-f]+)\\s+(0x[0-9a-f]+)\\s+(0x[0-9a-f]+)\\s+([^\\s]+)\\s+\\(([^\\)]+)\\)\\s+([^\\s]+)\\s*<?([\\d\\s]+)?>?\\s*" options:NSRegularExpressionCaseInsensitive error:nil];
    tty(@"/usr/sbin/kextstat", &kextStat);
    [self loadKextStat:kextStat];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(IBAction)showInfo:(id)sender{
    NSDictionary *kextStatInfo = [_kextStatData.selectedObjects firstObject];
    NSMutableArray *linkedKexts = NSMutableArray.array;
    for(NSString *i in [kextStatInfo objectForKey:@"indexes"]){
        NSNumber *index = [_kextStatDataDict objectForKey:i];
        [linkedKexts addObject:[[_kextStatData.content objectAtIndex:index.unsignedIntegerValue] objectForKey:@"name"]];
    }
    NSString *info = [NSString stringWithFormat:@"Bundle Identifier: %@\nVersion: %@\nAddress: %@\nSize: %@\nWired Bytes: %@\nReferences: %@\nUUID: %@\nLinked Against: %@", [kextStatInfo objectForKey:@"name"], [kextStatInfo objectForKey:@"version"], [kextStatInfo objectForKey:@"address"], [kextStatInfo objectForKey:@"size"], [kextStatInfo objectForKey:@"wired"], [kextStatInfo objectForKey:@"refs"], [kextStatInfo objectForKey:@"UUID"], [linkedKexts componentsJoinedByString:@", "]];
    [_kextStatInfo setString:info];
}

-(void)loadKextStat: (NSArray<NSString *> *)kextStat {
    _kextStatDataDict = NSMutableDictionary.dictionary;
    _kextStatData.content = nil;
    NSInteger counter = 0;
    for(NSString *string in kextStat){
        NSTextCheckingResult *match = [_kextStatExpression firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
        if(match.numberOfRanges > 0){
            NSArray *indexes = NSArray.array;
            @try{
                NSString *indexesStr = [string substringWithRange:[match rangeAtIndex:KSIndexes]];
                indexes = [indexesStr componentsSeparatedByString:@" "];
            } @catch (NSException *e) {}
            [_kextStatData addObject:@{
                   @"index": [string substringWithRange:[match rangeAtIndex:KSIndex]],
                   @"address": [string substringWithRange:[match rangeAtIndex:KSAddress]],
                   @"name": [string substringWithRange:[match rangeAtIndex:KSBundleId]],
                   @"refs": [string substringWithRange:[match rangeAtIndex:KSRefs]],
                   @"size": [string substringWithRange:[match rangeAtIndex:KSSize]],
                   @"version": [string substringWithRange:[match rangeAtIndex:KSVersion]],
                   @"wired": [string substringWithRange:[match rangeAtIndex:KSWired]],
                   @"UUID": [string substringWithRange:[match rangeAtIndex:KSUUID]],
                   @"indexes": indexes
            }];
            [_kextStatDataDict setObject:[NSNumber numberWithInteger:counter] forKey:[string substringWithRange:[match rangeAtIndex:KSIndex]]];
            ++counter;
        }
    }
    [_kextStatTable reloadData];
}

@end
