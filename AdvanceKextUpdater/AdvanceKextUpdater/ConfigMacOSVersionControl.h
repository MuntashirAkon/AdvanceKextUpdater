//
//  ConfigMacOSVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigMacOSVersionControl_h
#define ConfigMacOSVersionControl_h

@interface ConfigMacOSVersionControl: NSObject {}
@property NSString *higestVersion;
@property NSString *lowestVersion;

- (instancetype) initWithLowest: (NSString *) lowestVersion;
- (instancetype) initWithHighest: (id) higestVersion andLowest: (NSString *) lowestVersion;
- (BOOL) installableIn: (NSString *) macOSVersion;
- (BOOL) installableInCurrentVersion;
+ (NSString *) getMacOSVersion;
+ (int) getMacOSVersionInInt;
@end

#endif /* ConfigMacOSVersionControl_h */
