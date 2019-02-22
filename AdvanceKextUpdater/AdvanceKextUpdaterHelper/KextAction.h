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
#import "../AdvanceKextUpdater/KextFinder.h"
#import "../Shared/PreferencesHandler.h"

@interface KextAction : NSObject {
    NSString *kextLocation;
    @protected
    NSString *kextName;
    NSString *backupLocation;
    KextFinder *kextFinder;
    PreferencesHandler *preference;
}
- (instancetype) initWithKext: (NSString *) kextName;
- (BOOL) removeKext: (NSString *) kextName;
- (BOOL) doAction;
+ (BOOL) load: (NSString *) kextLocation;
+ (BOOL) unload: (NSString *) kextLocation;
@end

@interface KextInstall : KextAction {
    @protected
    KextConfig *config;
    NSString *targetFolder; // Unzipped location
}
- (instancetype) initWithKext: (NSString *) kextName;
- (BOOL) downloadRequirments;
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
