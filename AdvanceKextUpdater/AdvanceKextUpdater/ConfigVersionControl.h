//
//  ConfigVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigVersionControl_h
#define ConfigVersionControl_h

#import "ConfigMacOSVersionControl.h"
#import "KextConfig.h"

@interface ConfigVersionControl: NSObject {
@public
    NSString *currentVersion;
    NSArray<KextConfig *> *availableVersions;
    ConfigMacOSVersionControl *macOSVersion;
}
@end

#endif /* ConfigVersionControl_h */
