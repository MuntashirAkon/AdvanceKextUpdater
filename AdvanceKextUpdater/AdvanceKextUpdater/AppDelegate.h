//
//  AppDelegate.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KextHandler.h"

#define COLOR_GREEN [NSColor colorWithCalibratedRed:0 green:143/255.0f blue:0 alpha:1.0f] // Success
#define COLOR_RED [NSColor redColor] // Failure
#define COLOR_ORANGE [NSColor orangeColor] // Warning

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    KextHandler *kextHandler;
    NSMutableArray<NSString *> *installedKexts;
    NSArray<NSString *> *allTheKexts;
    NSDictionary<NSString *, NSURL *> *remoteKexts;
}
@end

