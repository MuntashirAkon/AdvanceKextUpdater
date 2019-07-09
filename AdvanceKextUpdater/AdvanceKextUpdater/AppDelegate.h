//
//  AppDelegate.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KextHandler.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    KextHandler *kextHandler;
    NSMutableArray<NSString *> *installedKexts;
    NSArray<NSString *> *allTheKexts;
}
// URL Handler
@property NSString * _Nullable urlVerb;
@property NSString * _Nullable urlKextName;
-(void)updateTables;
-(void)fetchKextInfo: (NSString * _Nonnull)kext;
@end

