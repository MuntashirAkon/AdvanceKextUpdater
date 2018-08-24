//
//  KextHandler.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef KextHandler_h
#define KextHandler_h

#define KEXT_REPO @"https://github.com/MuntashirAkon/AdvanceKextUpdater.git"
#define KEXT_BRANCH @"kext_db"

@interface KextHandler: NSObject {
    NSArray *kexts;
}
+ (BOOL) initDB;
+ (BOOL) checkForDBUpdate;
+ (NSString *) kextDBPath;
@end
#endif /* KextHandler_h */
