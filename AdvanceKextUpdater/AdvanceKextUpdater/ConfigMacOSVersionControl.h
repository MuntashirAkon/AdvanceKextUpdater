//
//  ConfigMacOSVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigMacOSVersionControl_h
#define ConfigMacOSVersionControl_h

@interface ConfigMacOSVersionControl: NSObject {
    NSString *higestVersion;
    NSString *lowestVersion;
}

- (BOOL) compareWith: (NSString *) macOSVersion;
- (BOOL) compareWithCurrent;

@end

#endif /* ConfigMacOSVersionControl_h */
