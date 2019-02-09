//
//  KextFinder.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KextFinder : NSObject
@property NSArray<NSString *> *installedKexts;
+(id)sharedKextFinder;
-(BOOL)isInstalled: (NSString *)kextName;
-(NSString *)findVersion: (NSString *)kextName;
-(NSArray<NSString *> *)findLocations: (NSString *)kextName;
-(void)updateList;
@end

NS_ASSUME_NONNULL_END
