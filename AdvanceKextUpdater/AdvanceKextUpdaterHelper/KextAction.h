//
//  KextAction.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 24/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextAction_h
#define KextAction_h

#import "../AdvanceKextUpdater/KextConfig.h"

@interface KextAction : NSObject {
    NSString *kextLocation;
}
@property (strong, nonatomic, readonly) NSString *kextName;
- (instancetype) initWithKext: (NSString *) kextName;
- (BOOL) doAction;
+ (NSString * _Nullable) find: (NSString *) kextName;
+ (BOOL) load: (NSString *) kextLocation;
+ (BOOL) unload: (NSString *) kextLocation;
+ (BOOL) removeKext: (NSString *) kextName;
+ (NSString * _Nullable) findInstalledVersion: (NSString *) kextName;
@end

@interface KextInstall : KextAction
@property (strong, nonatomic, readonly) KextConfig *config;
- (instancetype) initWithKext: (NSString *) kextName;
- (BOOL) removeConflicts;
- (BOOL) installRequirements;
- (BOOL) runPreInstallTask;
- (BOOL) installKext;
- (NSString *) runPostInstallTask;
@end

@interface KextUpdate : KextInstall
@end

@interface KextRemove : KextAction
@end

#endif /* KextAction_h */
