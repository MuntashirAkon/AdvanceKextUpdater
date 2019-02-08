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
@property NSDictionary *kextStatDataDict;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *kextStat = NSArray.array;
    tty(@"/usr/sbin/kextstat", &kextStat);
    //NSLog(@"%@", kextStat);
    _kextStatExpression = [NSRegularExpression regularExpressionWithPattern:@"\\s*(\\d+)\\s+(\\d+)\\s+(0x[0-9a-f]+)\\s+(0x[0-9a-f]+)\\s+(0x[0-9a-f]+)\\s+([^\\s]+)\\s+\\(([^\\)]+)\\)\\s+([^\\s]+)\\s*(<[\\d\\s]+>)?\\s*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *htmlString = [kextStat objectAtIndex:2];
    NSTextCheckingResult *match = [_kextStatExpression firstMatchInString:htmlString options:0 range:NSMakeRange(0, [htmlString length])];
    NSRange matchRange = [match rangeAtIndex:KSUUID];
    //NSString *matchString = [htmlString substringWithRange:matchRange];
    NSLog(@"%@", [htmlString substringWithRange:matchRange]);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)stringToKextStat:(NSString *)string {
    NSTextCheckingResult *match = [_kextStatExpression firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    // TODO
}

@end
